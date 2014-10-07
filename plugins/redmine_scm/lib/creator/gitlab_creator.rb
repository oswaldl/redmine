require 'redmine_gitlab/gitlab_methods'

class GitlabCreator < SCMCreator
  extend RedmineGitlab::GitlabMethods

  def self.included(base)
    base.send(:include, InstanceMethods)
  end

  class << self

    def enabled?
      if options
        if options['path']
          if !options['gitlab'] || File.executable?(options['gitlab'])
            return true
          else
            Rails.logger.warn "'#{options['gitlab']}' cannot be found/executed - ignoring '#{scm_id}"
          end
        else
          Rails.logger.warn "missing path for '#{scm_id}'"
        end
      end

      false
    end

    # path : /var/scm_repo/gitlab/cdcdc
    # repository : gitlab
    def create_repository(path, repository = nil)
      puts "create_repository----------------222222-----#{path}-----#{repository}----"

      #create project on gitlab
      if User.current.gitlab_token.nil?
        raise "no gitlab token found in user #{User.current.login}"
      end

      attrs = {}
      attrs['token'] = User.current.gitlab_token;
      attrs['title'] = repository.identifier;
      attrs['description'] = 'this repository is created by zycode.';
      attrs['visibility'] = true;
      attrs['project_identifier'] = repository.project.identifier;
      gitlab_create(attrs);


      # init git and do fetch
      args = [ git_command, 'init' ]
      append_options(args)
      args << path
      if system(*args)
        if options['update_server_info']
          Dir.chdir(path) do
            system(git_command, 'update-server-info')
          end
        end
        true
      else
        false
      end
    end

    def access_root_url(path, repository)
      (repository.url.nil? || repository.url == "") ? (ScmConfig['gitlab']['url'].to_s+'/'+(repository.project.identifier)) : repository.root_url
    end

    def access_url(path, repository)
      (repository.url.nil? || repository.url == "") ? (ScmConfig['gitlab']['url'].to_s+'/'+(repository.project.identifier)) : repository.url
    end

    def repository_name(path)
      matches = %r{^(?:.*/)?([^/]+?)(\\.git)?/?$}.match(path)
      matches ? matches[1] : nil
    end


    private

    def git_command
      options['git'] || Redmine::Scm::Adapters::GitAdapter::GIT_BIN
    end

  end

end