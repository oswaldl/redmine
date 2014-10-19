#require_dependency 'repositories_helper'
#require_dependency 'scm_repositories_helper_patch'

# module RepositoriesHelper
#   def github_field_tags(form, repository)
#     return '';
#   end
# end

module SnowballRepoHelperPatch

  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    puts "** including SnowballRepoHelperPatch"

    base.class_eval do
      unloadable

      alias_method_chain :github_field_tags, :add

      #alias_method_chain :repository_field_tags,        :sec
    end

    #base.send(:github_field_tags, nil, nil)

  end

  module ClassMethods
  end

  module InstanceMethods

    # def repository_field_tags(form, repository)
    #   return ''
    # end

    def github_field_tags_with_add(form, repository)
      puts "** steps in github_field_tags_with_add"


      # urltag = form.text_field(:url, :size => 60,
      #                          :required => true,
      #                          :disabled => !repository.safe_attribute?('url'))
      #
      # if repository.new_record? && GithubCreator.enabled? && !limit_exceeded
      #   if defined? observe_field # Rails 3.0 and below
      #     add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
      #   else # Rails 3.1 and above
      #     add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
      #   end
      #   urltag << add
      #   urltag << hidden_field_tag(:operation, '', :id => 'repository_operation')
      #   unless request.post?
      #     path = @project.identifier
      #     if defined? observe_field # Rails 3.0 and below
      #       urltag << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
      #     else # Rails 3.1 and above
      #       # TODO: 这里是值,一般pattern应该是https://github.com/用户名/path.git
      #       urltag << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
      #     end
      #   end
      #   note = "#{l(:text_github_repository_note_new)} (eg. https://github.com/gorebill/test.git)"
      # elsif repository.new_record?
      #   note = '(https://github.com/)'
      # end
      #
      # githubtags  = content_tag('p', urltag + '<br />'.html_safe + note)
      # githubtags << content_tag('p', form.text_field(:login, :size => 30)) +
      #     content_tag('p', form.password_field(:password, :size => 30,
      #                                          :name => 'ignore',
      #                                          :value => ((repository.new_record? || repository.password.blank?) ? '' : ('x'*15)),
      #                                          :onfocus => "this.value=''; this.name='repository[password]';",
      #                                          :onchange => "this.name='repository[password]';") +
      #         '<br />'.html_safe + l(:text_github_credentials_note))

      # FIXME: 这里会出错? 粗略判定是Setting的@api找不到
      # if !Setting.autofetch_changesets? && GithubCreator.can_register_hook?
      #   puts '** ck pt 4'
      #   githubtags << content_tag('p', form.check_box(:extra_register_hook, :disabled => repository.extra_hook_registered) + ' ' +
      #       l(:text_github_register_hook_note))
      # end


      githubtags = content_tag('p', form.text_field(
          :url, :label => l(:gh_field_repository_url),
          :size => 60, :required => true) +#, :readonly => 'readonly'
          '<br />'.html_safe +
          l(:gh_text_repository_url_note))

      githubtags << content_tag('p', form.text_field(:login, :size => 30))
      githubtags << content_tag('p', form.password_field(
          :password, :size => 30, :name => 'ignore',
          :value => ((repository.new_record? || repository.password.blank?) ? '' : ('x'*15)),
          :onfocus => "this.value=''; this.name='repository[password]';",
          :onchange => "this.name='repository[password]';"))


      githubtags << hidden_field_tag(:operation, 'add', :id => 'repository_operation')
      unless request.post?
        path = GithubCreator.access_root_url(path, repository)
        if GithubCreator.repository_exists?(@project.identifier) && @project.respond_to?(:repositories)
          offset = @project.repositories.select{ |r| r.created_with_scm }.size.to_s
          if path.sub!(%r{\.git$}, '.' + offset + '.git').nil?
            path << '.' + offset
          end
        end
        if defined? observe_field # Rails 3.0 and below
          githubtags << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
        else # Rails 3.1 and above
          githubtags << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
          # add change identifier js

        end
        #gitlabtags << javascript_tag("$('#repository_identifier').bind('mouseleave',function(){console.log('ddd');};")
        #githubtags << javascript_tag("$('#repository_identifier').change(function() { $('#repository_url').val('#{escape_javascript(path)}'+'/'+$('#repository_identifier').val());});")


        githubtags
      end

    end
  end
end