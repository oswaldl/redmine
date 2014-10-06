require 'gitlab'

module RedmineGitlab
	module GitlabMethods
		def gitlab_create(attrs)
			gitlab = gitlab_configure(attrs['token'])
			gitlab.create_project(attrs['title'], description: attrs['description'], visibility_level: attrs['visibility'])
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
