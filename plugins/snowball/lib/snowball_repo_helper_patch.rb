#require_dependency 'repositories_helper'
#require_dependency 'scm_repositories_helper_patch'

# module RepositoriesHelper
#   def github_field_tags(form, repository)
#     return '';
#   end
# end

module SnowballRepoHelperPatch

  def self.included(base)
    puts "** including SnowballRepoHelperPatch"

    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)

    base.class_eval do
      unloadable

      alias_method_chain :github_field_tags, :add

      #alias_method_chain :repository_field_tags,        :sec
    end

    #base.send(:github_field_tags, nil, nil)

    puts "** including SnowballRepoHelperPatch end"
  end

  module ClassMethods
  end

  module InstanceMethods

    # def repository_field_tags(form, repository)
    #   return ''
    # end

    def github_field_tags_with_add(form, repository)
      puts "** steps in github_field_tags_with_add"


      urltag = form.text_field(:url, :size => 60,
                               :required => true,
                               :disabled => !repository.safe_attribute?('url'))

      if repository.new_record? && GithubCreator.enabled? && !limit_exceeded
        if defined? observe_field # Rails 3.0 and below
          add = submit_tag(l(:button_create_new_repository), :onclick => "$('repository_operation').value = 'add';")
        else # Rails 3.1 and above
          add = submit_tag(l(:button_create_new_repository), :onclick => "$('#repository_operation').val('add');")
        end
        # urltag << add
        urltag << hidden_field_tag(:operation, 'add', :id => 'repository_operation')#这里需要add这个参数由scm_repositories_controller_patch处理
        unless request.post?
          path = @project.identifier
          if defined? observe_field # Rails 3.0 and below
            urltag << javascript_tag("$('repository_url').value = '#{escape_javascript(path)}';")
          else # Rails 3.1 and above
            # TODO: 这里是值,一般pattern应该是https://github.com/用户名/path.git
            # urltag << javascript_tag("$('#repository_url').val('#{escape_javascript(path)}');")
            urltag << javascript_tag("$('#repository_url').val('https://github.com/gorebill/test.git');")
          end
        end
        note = "#{l(:text_github_repository_note_new)} (eg. https://github.com/gorebill/test.git)"
      elsif repository.new_record?
        note = '(https://github.com/)'
      end

      githubtags  = content_tag('p', urltag + '<br />'.html_safe + note)
      githubtags << content_tag('p', form.text_field(:login, :size => 30)) +
          content_tag('p', form.password_field(:password, :size => 30,
                                               :name => 'ignore',
                                               :value => ((repository.new_record? || repository.password.blank?) ? '' : ('x'*15)),
                                               :onfocus => "this.value=''; this.name='repository[password]';",
                                               :onchange => "this.name='repository[password]';") +
              '<br />'.html_safe + l(:text_github_credentials_note))


      if repository.new_record?
        # 追加project-的前缀显示
        githubtags << javascript_tag("$('<label>#{@project.identifier.to_s}-</label>')
          .insertBefore($('#repository_identifier'))
          .attr('id','identifier-prefix')
          .css('margin-left',0)
          .css('float','none')
          .css('font-weight','normal')
          .css('padding','1px 4px')
          .css('border','1px solid #e0e2e3')
          .css('height','22px')
          .css('display','inline-block')
          .css('width','auto')
          .css('border-right','none')
          .css('background','#fff')
          .css('border-top-left-radius','3px')
          .css('border-bottom-left-radius','3px');
        ")

        # 修正repo.identifier
        githubtags << javascript_tag("$('input#repository_identifier').val(
          $('input#repository_identifier').val().replace(/^#{@project.identifier.to_s}-/,''))
        ");

        # 提交时追加project-作为前缀
        githubtags << javascript_tag("$('form#repository-form').bind('submit',function(){
          var prefix=$(this).find('#identifier-prefix').hide().text();
          var identifier=$(this).find('input#repository_identifier');
          $(identifier).val(prefix + $(identifier).val()).attr('readonly','readonly');
        });")
      end

      githubtags
    end
  end
end