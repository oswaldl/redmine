# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
get 'snowball_project_vote', :to => 'snowball_project_vote#index'
post 'post/:id/snowball_project_vote', :to => 'snowball_project_vote#vote'

#get 'snowball_project_vote/hello', :to=>'snowball_project_vote#hello'

match 'snowball_project_vote/:action(.:format)', :controller => 'snowball_project_vote', :via => [:get, :post, :put]


Rails.application.routes.draw do
  get 'issues/:issue_id/vote', :to => 'snowball_project_vote#get'
  post 'issues/:issue_id/vote', :to => 'snowball_project_vote#add'
  get 'issues/:project_id/vote/result', :to => 'snowball_project_vote#result'


  get 'projects/:id/repository/:repository_id/fork', :to => 'repositories#fork'

  match '/snowball_repo/create_fork/:id', :to => 'snowball_repo#create_fork', :via => [:get, :post, :put]#, :id => /\d+/
  match '/snowball_repo/new_pull_request/:id', :to => 'snowball_repo#new_pull_request', :via => [:get, :post, :put]
  match '/snowball_repo/new_pull_request_submit/:id', :to => 'snowball_repo#new_pull_request_submit', :via => [:get, :post, :put]

  match '/snowball_repo/show_pull_requests/:id', :to => 'snowball_repo#show_pull_requests', :via => [:get, :post, :put]
  match '/snowball_repo/merge_pull_request/:id', :to => 'snowball_repo#merge_pull_request', :via => [:get, :post, :put]
  match '/snowball_repo/merge_pull_request_submit/:id', :to => 'snowball_repo#merge_pull_request_submit', :via => [:get, :post, :put]
end

