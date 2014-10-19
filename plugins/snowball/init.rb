require 'redmine'
require 'snowball_repo_helper_patch'
require 'snowball_github'

require_dependency 'snowball_hook_listener'
require_dependency 'scm_repositories_helper_patch'
#require_dependency 'snowball_repo_helper_patch'

Rails.configuration.to_prepare do
  #unless Project.included_modules.include?(ScmProjectPatch)
  #  Project.send(:include, ScmProjectPatch)
  #end

  unless ScmRepositoriesHelperPatch::InstanceMethods.included_modules.include?(SnowballRepoHelperPatch)
    ScmRepositoriesHelperPatch::InstanceMethods.send(:include, SnowballRepoHelperPatch)
  end

  unless Repository::Github.included_modules.include?(SnowballGithub)
    Repository::Github.send(:include, SnowballGithub)
  end

  # unless GithubCreator.included_modules.include?(SnowballGithubCreatorPatch)
  #   GithubCreator.send(:include, SnowballGithubCreatorPatch)
  # end

  # unless ScmRepositoriesControllerPatch::InstanceMethods.included_modules.include?(SnowballRepoControllerGithubPatch)
  #   ScmRepositoriesControllerPatch::InstanceMethods.send(:include, SnowballRepoControllerGithubPatch)
  # end

  #unless RepositoriesController.included_modules.include?(ScmRepositoriesControllerPatch)
  #  RepositoriesController.send(:include, ScmRepositoriesControllerPatch)
  #end
end

Redmine::Plugin.register :snowball do
  name 'Snowball plugin'
  author 'gorebill'
  url 'http://foo.com'
  author_url 'http://foo'
  description '开源社区集成插件'
  version '0.0.1'






# There are five menus that you can extend:
#   :top_menu - the top left menu
#   :account_menu - the top right menu with sign in/sign out links
#   :application_menu - the main menu displayed when the user is not inside a project
#   :project_menu - the main menu displayed when the user is inside a project
#   :admin_menu - the menu displayed on the Administration page (can only insert after Settings, before Plugins)
# Available options are:
#
# :param - the parameter key that is used for the project id (default is :id)
# :if - a Proc that is called before rendering the item, the item is displayed only if it returns true
# :caption - the menu caption that can be:
#   a localized string Symbol
#   a String
#   a Proc that can take the project as argument
# :before, :after - specify where the menu item should be inserted (eg. :after => :activity)
# :first, :last - if set to true, the item will stay at the beginning/end of the menu (eg. :last => true)
# :html - a hash of html options that are passed to link_to when rendering the menu item

  #project_module :snowball do

    menu :application_menu, :snowball_project_vote, { :controller => 'snowball_project_vote', :action => 'index' }, :caption => '开源社区菜单测试'

    permission :view_polls, :snowball_project_vote => :index
    permission :hello_polls, :snowball_project_vote => :hello
    #permission :snowball, {:snowball => [:hello]}, :public => true
    menu :project_menu, :snowball_project_vote, {:controller => 'snowball_project_vote', :action => 'hello'},
         :caption => '开源社区Project Menu', :first => true, :param => :project_id

    #permission :snowball, { :snowball => [:test] }, :public => true
    #menu :project_menu, :snowball, { :controller => 'snowball_project_vote', :action => 'test' }, :caption => '开源社区Project Menu', :after => :activity, :param => :project_id
  #end


  #追加github建库设置
  # settings :default => {},
  #          :partial => 'settings/snowball_github_settings'


end


#Redmine::Scm::Base.add('Github')

