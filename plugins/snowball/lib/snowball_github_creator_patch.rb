require 'octokit'

require_dependency 'repository/github'

module SnowballGithubCreatorPatch

  def self.included(base)
    puts "** including SnowballGithubCreatorPatch"

    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      # def self.github_configure(token)
      #   puts "** calling github_configure in SnowballRepoControllerGithubPatch"
      #
      #   Repository::Github.client(endpoint: (ScmConfig['github']['url'].to_s + '/api/v3'), private_token: token)
      # end
      #
      # # title is the repository name
      # # project_identifier is the group name
      # def self.github_create(attrs)
      #   puts "** calling github_create in SnowballRepoControllerGithubPatch"
      #
      #   puts "** attrs= #{attrs}"
      #
      #   if attrs['project_identifier'].nil?
      #     raise("no group id in attrs['project_identifier']")
      #   end
      #
      #   #github = self.github_configure(attrs['token'])
      #
      #   # ready to check github project exist
      #   github_project_data = nil
      #   begin
      #     github_project_data = github.project(attrs['title'])
      #   rescue Exception => e
      #     puts e
      #   end
      #
      #   if github_project_data.nil?
      #     github_project_data = github.create_project(attrs['title'], description: attrs['description'], visibility_level: attrs['visibility'])
      #   end
      #
      #   # ready to check github group exist
      #   github_group_data = nil
      #   begin
      #     github_group_data = github.group(attrs['project_identifier'])
      #   rescue Exception => e
      #     puts e
      #   end
      #
      #   if github_group_data.nil?
      #     github_group_data = github.create_group(attrs['project_identifier'], attrs['project_identifier'])
      #   end
      #
      #   # ready to do transfer
      #   if github_project_data.namespace.name != github_group_data.name
      #     github.transfer_project_to_group(github_group_data.id, github_project_data.id)
      #   end
      #
      #
      #
      #
      #   # add webhook
      #   # http://zyac-open.chinacloudapp.cn:3000/github_hook?project_id=test_project&key=j2g7kds9341hj6sdk
      #   webhook_url = Setting.protocol.downcase + '://' + Setting.host_name + '/github_hook?project_id=' + attrs['project_identifier'] + '&key=' + Setting.sys_api_key
      #   github.add_project_hook(github_project_data.id, webhook_url)
      # end

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

        # 获取一些额外的参数，目前未用到
        github_extra=SnowballRepoGithub.find_by_repo_id(repository.id)

        # TODO 这里最好检验一下repository.identifier是否以#{project}-开头
        # ...

        puts "** chdir to #{ScmConfig['github']['path']}"

        # go to root path, eg: /var/scm_repo/github
        Dir.chdir(ScmConfig['github']['path']) do
          args = [ git_command, 'clone' ]
          append_options(args)

          # 不要加Scm的append
          subfix_append=''#ScmConfig['github']['append'].to_s

          tmp_url = URI(repository.url)

          #reference http://www.ruby-doc.org/stdlib-1.9.3/libdoc/uri/rdoc/URI.html
          tmp_url = [tmp_url.scheme ? tmp_url.scheme : 'http',
                     '://',
                     (repository.login.nil? || repository.login=='' ? '' : (repository.login + ':' + repository.password + '@')),
                     tmp_url.host,
                     tmp_url.path,
                     (tmp_url.query ? '?':''), tmp_url.query,
                     subfix_append
          ].join('')

          puts "** composite github uri=#{tmp_url}"

          # 这里需要强制加project-
          args << tmp_url << default_path(repository.identifier)

          puts "** system args=#{args.join(' ')}"

          # ref: https://github.com/octokit/octokit.rb
          # Provide authentication credentials

          # 当login以及password不为空时进行hook
          if !repository.login.nil? && repository.login != '' && !repository.password.nil? && repository.password != ''
            client = Octokit::Client.new(:login => repository.login.to_s, :password => repository.password.to_s)
            # Fetch the current user
            client.user

            # 参考github_creator
            hook_response=client.create_hook(
                Octokit::Repository.from_url(repository.url.sub(%r{\.git$},'')),
                'redmine',
                {
                    :address                             => "#{Setting.protocol}://#{Setting.host_name}",
                    :project                             => repository.project.identifier,
                    :api_key                             => Setting.sys_api_key,
                    :fetch_commits                       => 1,
                    :update_redmine_issues_about_commits => 1
                    # :url => Setting.protocol.downcase + '://' + Setting.host_name + "/github_hook?project_id=#{repository.project.identifier}&repository_id=#{repository.identifier}",
                    # :content_type => 'json'
                },
                {
                    :events => ['push', 'pull_request'],
                    :active => true
                }
            )

            puts "** hooked to #{repository.url}: #{hook_response.to_attrs}"

            return false unless hook_response.is_a?(Sawyer::Resource)
          else
            # 当login以及password为空时进行匿名,不hook
            # go ahead
          end

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

      rescue Octokit::Error => error
        Rails.logger.error error.message
        false
      end

      # just return the name, as it's remote repository
      def default_path(identifier)
        identifier
      end

      def self.access_root_url(path, repository)
        (repository.url.nil? || repository.url == "") ? (ScmConfig['github']['url'].to_s + '/' + (repository.project.identifier)) : repository.root_url
      end

      def self.access_url(path, repository)
        (repository.url.nil? || repository.url == "") ? (ScmConfig['github']['url'].to_s + '/' + (repository.project.identifier)) : repository.url
      end

      def self.repository_name(path)

        # ref: http://git-scm.com/docs/git-clone

        matches = %r{^(?:.*/)?([^/]+?)(\\.git)?/?$}.match(path)
        matches ? matches[1] : nil
      end


      private

      def self.git_command
        puts "** asking self.git_command in SnowballGithubCreatorPatch"

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




