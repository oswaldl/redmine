
#Ref: http://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial#Hooks-in-views

class SnowballHookListener < Redmine::Hook::ViewListener



end

class SnowballVoteHeaderHooks < Redmine::Hook::ViewListener
  #Ref: http://www.redmine.org/projects/redmine/wiki/Plugin_Tutorial#Improving-the-plugin-views
  def view_layouts_base_html_head(context = {})
    o = stylesheet_link_tag('snowball_project_vote', :plugin => 'snowball')
    o << javascript_include_tag('snowball_project_vote', :plugin => 'snowball')
    return o
  end
end

class SnowballVoteLayoutBaseContentHooks < Redmine::Hook::ViewListener
  #Ref: http://www.redmine.org/projects/redmine/repository/entry/tags/2.0.0/app/views/layouts/base.html.erb
  #Ref: http://www.redmine.org/projects/redmine/repository/entry/tags/2.0.0/app/views/issues/show.html.erb

  #view_issues_show_details_bottom 这里不选用，因为需要在list的页面也引用模版页面
  render_on :view_layouts_base_content, :partial => 'snowball_project_vote/view_layouts_base_content'
end







