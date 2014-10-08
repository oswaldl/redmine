require 'redmine/scm/adapters/gitlab_adapter'

class Repository::Gitlab < Repository

  class << self

    def scm_adapter_class
      Redmine::Scm::Adapters::GitlabAdapter
    end

    def scm_name
      'Gitlab'
    end



  end # end class methods

  def branches
    scm.branches
  end

  def heads_from_branches_hash
    h1 = extra_info || {}
    h  = h1.dup
    h["branches"] ||= {}
    h['branches'].map{|br, hs| hs['last_scmid']}
  end

  def fetch_changesets
    #remote fetch
    # http_path = (root_url.nil? || root_url == "") ? url : root_url
    #
    # start_index = http_path.rindex('/')
    # end_index = http_path.length
    #
    # repo_path = ScmConfig['gitlab']['path'].to_s + http_path[start_index,end_index] +ScmConfig['gitlab']['append'].to_s
    #
    # logger.info "cd #{repo_path} and do #{git_command} 'fetch -q --all -p'"
    # args = [ git_command, 'fetch' ]
    # args << '-q'
    # args << '--all'
    # args << '-p'
    # Dir.chdir(repo_path) do
    #   system(*args)
    # end


    #local fetch
    scm_brs = branches
    return if scm_brs.nil? || scm_brs.empty?

    h1 = extra_info || {}
    h  = h1.dup
    repo_heads = scm_brs.map{ |br| br.scmid }
    h["heads"] ||= []
    prev_db_heads = h["heads"].dup
    if prev_db_heads.empty?
      prev_db_heads += heads_from_branches_hash
    end
    return if prev_db_heads.sort == repo_heads.sort

    h["db_consistent"]  ||= {}
    if changesets.count == 0
      h["db_consistent"]["ordering"] = 1
      merge_extra_info(h)
      self.save
    elsif ! h["db_consistent"].has_key?("ordering")
      h["db_consistent"]["ordering"] = 0
      merge_extra_info(h)
      self.save
    end
    save_revisions(prev_db_heads, repo_heads)
  end

  def save_revisions(prev_db_heads, repo_heads)
    h = {}
    opts = {}
    opts[:reverse]  = true
    opts[:excludes] = prev_db_heads
    opts[:includes] = repo_heads

    revisions = scm.revisions('', nil, nil, opts)
    return if revisions.blank?

    # Make the search for existing revisions in the database in a more sufficient manner
    #
    # Git branch is the reference to the specific revision.
    # Git can *delete* remote branch and *re-push* branch.
    #
    #  $ git push remote :branch
    #  $ git push remote branch
    #
    # After deleting branch, revisions remain in repository until "git gc".
    # On git 1.7.2.3, default pruning date is 2 weeks.
    # So, "git log --not deleted_branch_head_revision" return code is 0.
    #
    # After re-pushing branch, "git log" returns revisions which are saved in database.
    # So, Redmine needs to scan revisions and database every time.
    #
    # This is replacing the one-after-one queries.
    # Find all revisions, that are in the database, and then remove them
    # from the revision array.
    # Then later we won't need any conditions for db existence.
    # Query for several revisions at once, and remove them
    # from the revisions array, if they are there.
    # Do this in chunks, to avoid eventual memory problems
    # (in case of tens of thousands of commits).
    # If there are no revisions (because the original code's algorithm filtered them),
    # then this part will be stepped over.
    # We make queries, just if there is any revision.
    limit = 100
    offset = 0
    revisions_copy = revisions.clone # revisions will change
    while offset < revisions_copy.size
      scmids = revisions_copy.slice(offset, limit).map{|x| x.scmid}
      recent_changesets_slice = changesets.where(:scmid => scmids)
      # Subtract revisions that redmine already knows about
      recent_revisions = recent_changesets_slice.map{|c| c.scmid}
      revisions.reject!{|r| recent_revisions.include?(r.scmid)}
      offset += limit
    end
    revisions.each do |rev|
      transaction do
        # There is no search in the db for this revision, because above we ensured,
        # that it's not in the db.
        save_revision(rev)
      end
    end
    h["heads"] = repo_heads.dup
    merge_extra_info(h)
    self.save
  end
  private :save_revisions

  def save_revision(rev)
    parents = (rev.parents || []).collect{|rp| find_changeset_by_name(rp)}.compact
    changeset = Changeset.create(
        :repository   => self,
        :revision     => rev.identifier,
        :scmid        => rev.scmid,
        :committer    => rev.author,
        :committed_on => rev.time,
        :comments     => rev.message,
        :parents      => parents
    )
    unless changeset.new_record?
      rev.paths.each { |change| changeset.create_change(change) }
    end
    changeset
  end
  private :save_revision

  private

  def git_command
    Redmine::Scm::Adapters::GitAdapter::GIT_BIN
  end

end
