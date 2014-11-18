require 'octokit'

require_dependency 'repository/github'

module SnowballGithubHookUpdaterPatch

  def self.included(base)
    puts "** including SnowballGithubHookUpdaterPatch"

    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      alias_method_chain :update_repository, :local_dir

    end

  end

  module ClassMethods
  end


  module InstanceMethods
    # Fetches updates from the remote repository
    def update_repository_with_local_dir(repository)
      puts "** calling update_repository in SnowballGithubHookUpdaterPatch repo=#{repository}"

      command = git_command('fetch origin')
      if exec(command, repository.root_url)
        command = git_command("fetch origin \"+refs/heads/*:refs/heads/*\"")
        exec(command, repository.root_url)
      end
    end
  end

end




