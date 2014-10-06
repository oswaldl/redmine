#
# the gitlab form & inputs when creating a gitlab-repo

module RepositoriesHelper
  def gitlab_field_tags(form, repository)
    gitlabtags = content_tag('p', form.text_field(
                       :url, :label => l(:gl_field_repository_url),
                       :size => 60, :required => true, :readonly => 'readonly') +
                      '<br />'.html_safe +
                      l(:gl_text_repository_url_note))

    gitlabtags << content_tag('p', form.text_field(:login, :size => 30))
    gitlabtags << content_tag('p', form.password_field(
        :password, :size => 30, :name => 'ignore',
        :value => ((repository.new_record? || repository.password.blank?) ? '' : ('x'*15)),
        :onfocus => "this.value=''; this.name='repository[password]';",
        :onchange => "this.name='repository[password]';"))


    gitlabtags << hidden_field_tag(:operation, 'add', :id => 'repository_operation')
    unless request.post?
      path = GitlabCreator.access_root_url(path, repository)
      if GitlabCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
        offset = @project.repositories.select{ |r| r.created_with_scm }.size.to_s
        if path.sub!(%r{\.git$}, '.' + offset + '.git').nil?
          path << '.' + offset
        end
      end
      if defined? observe_field # Rails 3.0 and below
        gitlabtags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
      else # Rails 3.1 and above
        gitlabtags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
        # add change identifier js

      end
      #gitlabtags << javascript_tag("$('#repository_identifier').bind('mouseleave',function(){console.log('ddd');};")
      gitlabtags << javascript_tag("$('#repository_identifier').change(function() { $('#repository_url').val('#{escape_javascript(path)}'+'/'+$('#repository_identifier').val());});")

    end
  end

end
