# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'snowball_project_vote', :to => 'snowball_project_vote#index'
post 'post/:id/snowball_project_vote', :to => 'snowball_project_vote#vote'

#get 'snowball_project_vote/hello', :to=>'snowball_project_vote#hello'

match 'snowball_project_vote/:action(.:format)', :controller => 'snowball_project_vote'


Rails.application.routes.draw do
  get 'issues/:issue_id/vote', :to => 'snowball_project_vote#get'
  post 'issues/:issue_id/vote', :to => 'snowball_project_vote#add'
  get 'issues/:project_id/vote/result', :to => 'snowball_project_vote#result'
end

