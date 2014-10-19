require_dependency 'repository/github'

module SnowballGithubCreatorPatch

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    puts "** including SnowballGithubCreatorPatch"

    base.class_eval do
      unloadable

      def self.github_configure(token)
        puts "** calling github_configure in SnowballRepoControllerGithubPatch"

        #Repository::Github.client(endpoint: (ScmConfig['github']['url'].to_s + '/api/v3'), private_token: token)
      end

      # title is the repository name
      # project_identifier is the group name
      def self.github_create(attrs)
        puts "** calling github_create in SnowballRepoControllerGithubPatch"

        if attrs['project_identifier'].nil?
          raise("no group id in attrs['project_identifier']")
        end

        github = self.github_configure(attrs['token'])

        # ready to check github project exist
        github_project_data = nil
        begin
          github_project_data = github.project(attrs['title'])
        rescue Exception => e
          puts e
        end

        if github_project_data.nil?
          github_project_data = github.create_project(attrs['title'], description: attrs['description'], visibility_level: attrs['visibility'])
        end

        # ready to check github group exist
        github_group_data = nil
        begin
          github_group_data = github.group(attrs['project_identifier'])
        rescue Exception => e
          puts e
        end

        if github_group_data.nil?
          github_group_data = github.create_group(attrs['project_identifier'], attrs['project_identifier'])
        end

        # ready to do transfer
        if github_project_data.namespace.name != github_group_data.name
          github.transfer_project_to_group(github_group_data.id, github_project_data.id)
        end




        # add webhook
        # http://zyac-open.chinacloudapp.cn:3000/github_hook?project_id=test_project&key=j2g7kds9341hj6sdk
        webhook_url = Setting.protocol.downcase + '://' + Setting.host_name + '/github_hook?project_id=' + attrs['project_identifier'] + '&key=' + Setting.sys_api_key
        github.add_project_hook(github_project_data.id, webhook_url)
      end

      def self.enabled?
        puts "** asking enable? in SnowballGithubCreatorPatch"

        if options
          if options['path']
            if !options['github'] || File.executable?(options['github'])
              return true
            else
              Rails.logger.warn "'#{options['github']}' cannot be found/executed - ignoring '#{scm_id}"
            end
          else
            Rails.logger.warn "missing path for '#{scm_id}'"
          end
        end

        false
      end

      # path : /var/scm_repo/github/repo_demp
      # repository : github
      def self.create_repository(path, repository = nil)
        puts "** calling SnowballGithubCreatorPatch::create_repository"

        # #create project on github
        # if User.current.github.nil?
        #   raise "no github token found in user #{User.current.login}"
        # end

        attrs = {}
        # attrs['token'] = User.current.github_token;
        # FIXME: 这里token没法填，先留空
        attrs['token'] = 'foo';
        attrs['title'] = repository.identifier;
        attrs['description'] = 'this repository is created by zycode.';
        attrs['visibility'] = true;
        attrs['project_identifier'] = repository.project.identifier;
        self.github_create(attrs);


        # init git and do fetch

        puts "** chdir to #{ScmConfig['github']['path']}"

        # go to root path, eg: /var/scm_repo/github
        Dir.chdir(ScmConfig['github']['path']) do
          args = [ git_command, 'clone' ]
          append_options(args)

          #--------set username & password in url------------
          # TODO http or https or ssh
          tmp_url = repository.url.gsub("http://","")
          tmp_url = repository.login + ':' + repository.password + '@' + tmp_url

          args << ('http://' + tmp_url + ScmConfig['github']['append'].to_s)
          #--------------------


          if system(*args)
            if options['update_server_info']
              Dir.chdir(path) do
                args = [ git_command, 'fetch' ]
                args << '-q'
                args << '--all'
                args << '-p'
                system(*args)
              end
            end
            true
          else
            false
          end
        end


      end

      def self.access_root_url(path, repository)
        (repository.url.nil? || repository.url == "") ? (ScmConfig['github']['url'].to_s + '/' + (repository.project.identifier)) : repository.root_url
      end

      def self.access_url(path, repository)
        (repository.url.nil? || repository.url == "") ? (ScmConfig['github']['url'].to_s + '/' + (repository.project.identifier)) : repository.url
      end

      def self.repository_name(path)
        matches = %r{^(?:.*/)?([^/]+?)(\\.git)?/?$}.match(path)
        matches ? matches[1] : nil
      end


      private

      def self.git_command
        puts "asking self.git_command in SnowballGithubCreatorPatch"

        options['git'] || Redmine::Scm::Adapters::GitAdapter::GIT_BIN
      end



    end

    #base.send(:github_field_tags, nil, nil)

  end

  module ClassMethods
  end


  module InstanceMethods

  end

end




