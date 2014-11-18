require 'octokit'

class SnowballRepoController < ApplicationController
  unloadable

  def index
  end

  def new_pull_request
    @repository=Repository.find_by_identifier(params[:repository_id])
    @project=@repository.project

    client=Octokit::Client.new(:login => @repository.login, :password => @repository.password)
    github=Octokit::Repository.from_url(@repository.url.sub(%r{\.git$},''));
    base=Octokit::Repository.from_url(@repository.fork_from.sub(%r{\.git$},''));

    @repo_base=client.repository(base);

    @repo_head=client.repository(github);

  end

  def new_pull_request_submit

    puts "** pulling pull_request..."

    # ref: http://octokit.github.io/octokit.rb/frames.html#!Octokit.html

    @repository=Repository.find(params[:id])
    @project=@repository.project

    client=Octokit::Client.new(:login => @repository.login, :password => @repository.password);
    base=Octokit::Repository.from_url(@repository.fork_from.sub(%r{\.git$},''));

    response=client.create_pull_request(
        base,
        params[:base_branch],
        params[:head_repo].sub(%r{/.*$},'')+':'+params[:head_branch],
        params[:pull_title],
        params[:pull_body]);

    if response.is_a?(Sawyer::Resource)
      puts "** response=#{response}"

      # 跳转到base的pull requst浏览页面
      # FIXME: 因为不知道base的repo是否redmine的repo，所以没法redirect过去，因此只跳转到当前repo的现实页面
      #redirect_to :controller=>'snowball_repo', :action=>'show_pull_requests', :id=>@repository.identifier;

      # ref: http://api.rubyonrails.org/classes/ActionController/Redirecting.html
      redirect_to "#{project_path(@project)}/repository/#{(@repository.identifier)}"
      return;
    else
      raise '服务器与Github连接异常，请稍后再试'
    end

  rescue Exception => error
    puts "** error=#{error}"
    #raise error
    render_error :message => error.to_s
  end

  def show_pull_requests

    @repository=Repository.find_by_identifier(params[:id])
    @project=@repository.project

    client=Octokit::Client.new(:login => @repository.login, :password => @repository.password)
    github=Octokit::Repository.from_url(@repository.url.sub(%r{\.git$},''));

    # ref: http://octokit.github.io/octokit.rb/Octokit/Client/PullRequests.html#pull_request_files-instance_method

    # pull requests files参考response
    # ref: https://developer.github.com/v3/pulls/#list-pull-requests-files

    # pull requests list
    # ref: https://developer.github.com/v3/pulls/#list-pull-requests
    # 对应页面https://github.com/gorebill/test/pulls
    response=client.pull_requests(github, :state => 'open')

    if !response.nil?
      @merge_requests=response;
    else
      raise '服务器与Github连接异常，请稍后再试'
    end

  rescue Exception=>error
    # raise error
    (render_error error.to_s; return)
  end

  def merge_pull_request
    @repository=Repository.find_by_identifier(params[:id])
    @project=@repository.project

    client=Octokit::Client.new(:login => @repository.login, :password => @repository.password)
    github=Octokit::Repository.from_url(@repository.url.sub(%r{\.git$},''));

    pull_number=params[:pull_number];

    response=client.pull_request(github, pull_number)
    #response=client.pull_request_comments(github, pull_number);

    if response.is_a?(Sawyer::Resource)
      @merge_request=response;
    else
      raise '服务器与Github连接异常，请稍后再试'
    end

  rescue Exception=>error
    # raise error
    (render_error error.to_s; return)
  end

  def merge_pull_request_submit
    puts "** merging pull request"

    oper_type=params[:oper_type];

    @repository=Repository.find(params[:id])

    client=Octokit::Client.new(:login => @repository.login, :password => @repository.password);
    github=Octokit::Repository.from_url(@repository.url.sub(%r{\.git$},''));


    # merge pull request
    # ref: http://octokit.github.io/octokit.rb/Octokit/Client/PullRequests.html#merge_pull_request-instance_method

    if oper_type=='close'
      response=client.close_pull_request(github, params[:merge_number]);

      if response.is_a?(Sawyer::Resource)
        redirect_to :controller=>'snowball_repo',:action=>'show_pull_requests',:id=>@repository.identifier
      else
        raise '服务器与Github连接异常，请稍后再试'
      end

    elsif oper_type=='merge'
      response=client.merge_pull_request(github, params[:merge_number]);

      if response.is_a?(Sawyer::Resource)
        redirect_to :controller=>'snowball_repo',:action=>'show_pull_requests',:id=>@repository.identifier
      else
        raise '服务器与Github连接异常，请稍后再试'
      end
    else
      raise "未定义的操作 (#{oper_type})"
    end

  rescue Exception=>error
    # raise error
    (render_error error.to_s; return)
  end

  def create_fork
    puts "** calling create_fork #{params}"

    # ref https://developer.github.com/v3/repos/forks/#create-a-fork
    # ref http://octokit.github.io/octokit.rb/Octokit/Client/Repositories.html#fork-instance_method

    # issue Github上Forking a Repository happens asynchronously.因此这里需要可能出现issue

    repo=params[:repository]

    #TODO: 目前这边的controller只针对Github

    fork_from=repo[:fork_from]
    fork_to=repo[:url].sub(%r{^.*//[^/]*/},'')
    repo_login=repo[:login]
    repo_password=repo[:password]
    repo_project=repo[:project]
    repo_identifier=repo[:identifier]

    if fork_from.nil?||''==fork_from||
        fork_to.nil?||''==fork_to||
        repo_login.nil?||''==repo_login||
        repo_password.nil?||''==repo_password||
        repo_project.nil?||''==repo_project||
        repo_identifier.nil?||''==repo_identifier

      raise 'Required fields should filled in with proper values.'
    end

    puts "fork_from=#{fork_from}, fork_to=#{fork_to}"

    # 这里的from好像用不着, 因为github上api只支持fork当前用户有权限的repo, 因此from和to都将是用同一个credentials
    #client_from = Octokit::Client.new(:login => repo[:fork_from_login], :password => repo[:fork_from_password])
    #client_from.user

    client_to=Octokit::Client.new(:login => repo_login, :password => repo_password)
    # client_to.user

    repo_src=Octokit::Repository.from_url(fork_from.sub(%r{\.git$},''));

    # response is a Sawyer::Resource
    response=client_to.fork(repo_src, {:organization => fork_to})#https://developer.github.com/v3/repos/forks/#create-a-fork

    # flag means success or not
    flag=response.is_a?(Sawyer::Resource) ? true : false
    # flag=true

    puts "#{response.to_s}"

    if flag
      # begin to clone

      # check whether github repo ready
      elapsed=0
      interval=6
      while !client_to.repository?(Octokit::Repository.from_url(response[:html_url]))
        puts "** waiting repo forked on github elapsed=#{elapsed}"

        sleep(interval)
        elapsed+=interval

        if elapsed > 300
          raise 'No github repo was found after 5 minutes.'
          break
        end
      end

      # override
      params[:repository][:url]=response[:clone_url]

      # set values for scm repo creation
      @project=Project.find(repo[:project])

      if create_with_scm(params) && @repository.errors.empty?
        redirect_to(settings_project_path(@project, :tab => 'repositories'))
      else
        err_msgs='';
        @repository.errors.full_messages.flatten.each do |msg|
          err_msgs << msg
        end

        redirect_to :controller => 'repositories', :action => 'fork', :id => @project.id, :repository_id => params[:id],
                    :error => err_msgs
        return
      end
    end

  rescue Exception => error
    if error.is_a?(Octokit::UnprocessableEntity)
      # flash[:error] = error.to_s
      (render_error 'Organization is not valid.'; return)
      # render(:action => 'create_fork')
    else
      # raise error
      (render_error error.to_s; return)
    end
  end




private
  def create_with_scm(params)
    puts '** step in create_with_scm in SnowballRepoController'

    puts "#{params}"

    puts 'snrc pt 1'
    interface = SCMCreator.interface(params[:repository_scm])
    if (interface && (interface < SCMCreator) && interface.enabled?)
      puts 'snrc pt 2'

      attributes = {}
      extra_attrs = {}
      params[:repository].each do |name, value|
        if name =~ %r{^extra_}
          extra_attrs[name] = value
        else
          attributes[name] = value
        end
      end

      puts 'snrc pt 3'
      if params[:operation].present? && params[:operation] == 'add'
        attributes = interface.sanitize(attributes)
      end

      puts 'snrc pt 4'
      puts "attributes=#{attributes}"
      @repository = Repository.factory(params[:repository_scm])
      if @repository.respond_to?(:safe_attribute_names) && @repository.safe_attribute_names.any?
        @repository.safe_attributes = attributes

        puts "@repository.safe_attributes=#{@repository.attributes}"
      else # Redmine < 2.2
        @repository.attributes = attributes
      end
      if extra_attrs.any?
        @repository.merge_extra_info(extra_attrs)
      end

      puts 'snrc pt 5'
      if @repository
        @repository.project = @project

        # 因为未在snowball_github加上safe的属性,又懒得改了,所以在这里直接加上
        @repository.fork_from = attributes['fork_from']

        puts 'snrc pt 6'
        if @repository.valid?
          puts 'snrc pt 7'
          if !ScmConfig['max_repos'] || ScmConfig['max_repos'].to_i == 0 ||
              @project.repositories.select{ |r| r.created_with_scm }.size < ScmConfig['max_repos'].to_i

            puts 'snrc pt 8'
            scm_create_repository(@repository, interface, attributes['url'])

          else
            @repository.errors.add(:base, :scm_repositories_maximum_count_exceeded, :max => ScmConfig['max_repos'].to_i)
          end
        end

        puts 'snrc pt 9'

        if request.post? && @repository.errors.empty? && @repository.save
          return true
        end
      end
    end

    return false
  end

  def scm_create_repository(repository, interface, url)
    puts "calling scm_create_repository in SnowballRepoController"

    name = interface.repository_name(url)
    if name
      path = interface.default_path(name)
      if interface.repository_exists?(name)
        repository.errors.add(:url, :already_exists)
      else
        Rails.logger.info "Creating reporitory: #{path}"
        interface.execute(ScmConfig['pre_create'], path, @project) if ScmConfig['pre_create']
        if result = interface.create_repository(path, repository)
          path = result if result.is_a?(String)
          interface.execute(ScmConfig['post_create'], path, @project) if ScmConfig['post_create']
          repository.created_with_scm = true
        else
          repository.errors.add(:base, :scm_repository_creation_failed)
          Rails.logger.error "Repository creation failed"
        end
      end

      repository.root_url = interface.access_root_url(path, repository)
      repository.url      = interface.access_url(path, repository)

      if interface.local? && !interface.belongs_to_project?(name, @project.identifier)
        flash[:warning] = l(:text_cannot_be_used_redmine_auth)
      end
    else
      repository.errors.add(:url, :should_be_of_format_local, :repository_format => interface.repository_format)
    end
  end

end
