require 'gitlab'

module RedmineGitlab
	module GitlabMethods

    # title is the repository name
    # project_identifier is the group name
		def gitlab_create(attrs)
      if attrs['project_identifier'].nil?
        raise("no group id in attrs['project_identifier']")
      end

			gitlab = gitlab_configure(attrs['token'])

      # ready to check gitlab project exist
      gitlab_project_data = nil
      begin
        gitlab_project_data = gitlab.project(attrs['title'])
      rescue Exception => e
        puts e
      end

      if gitlab_project_data.nil?
        gitlab_project_data = gitlab.create_project(attrs['title'], description: attrs['description'], visibility_level: attrs['visibility'])
      end

      # ready to check gitlab group exist
      gitlab_group_data = nil
      begin
        gitlab_group_data = gitlab.group(attrs['project_identifier'])
      rescue Exception => e
        puts e
      end

      if gitlab_group_data.nil?
        gitlab_group_data = gitlab.create_group(attrs['project_identifier'], attrs['project_identifier'])
      end

      # ready to do transfer
      gitlab.transfer_project_to_group(gitlab_group_data.id, gitlab_project_data.id)

      # add webhook
      # http://zyac-open.chinacloudapp.cn:3000/gitlab_hook?project_id=test_project&key=j2g7kds9341hj6sdk
      webhook_url = Setting.protocol.downcase + '://' + Setting.host_name + '/gitlab_hook?project_id=' + attrs['project_identifier'] + '&key=' + Setting.sys_api_key
      gitlab.add_project_hook(gitlab_project_data.id, webhook_url)
    end


		def gitlab_configure(token)
			Gitlab.client(endpoint: (ScmConfig['gitlab']['url'].to_s + '/api/v3'), private_token: token)
    end

    def fetch_set_token(user,username,password)
      request_url = ScmConfig['gitlab']['url'].to_s + '/api/v3/session'
      params = {}
      params["login"] = username
      params["password"] = password
      uri = URI.parse(request_url)
      res = Net::HTTP.post_form(uri, params)
      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          private_token = (JSON.parse(res.body))['private_token']
          if user
            user.gitlab_token = private_token
            user.save()
          end
          private_token
        when Net::HTTPUnauthorized
          "HTTPUnauthorized"
        else
          puts "error: #{res}"
          res.to_s
      end

    end
	end
end
