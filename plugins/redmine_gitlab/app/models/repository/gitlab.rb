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

  def fetch_changesets
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



end
