##
#RedMine IMAP Authentication Module
#
# All rights avoided, you are free to distribute or modify
# the source code under the terms you reserve the author information.
#
# Author:
#     Dingding Technology, Inc.
#     Sunding Wei <swei(at)dingding.me>
#
# File: redmine/app/models/auth_source_imap.rb
#
require "net/imap"
require 'timeout'

#
# HOWTO
#
# 1. Execute the SQL
#    INSERT INTO auth_sources (type, name) values ("AuthSourceIMAP", "IMAP")
# 2. Change as you like
# 3. Redmine: set the user authentication mode to IMAP
# 4. Restart your web server
#

class AuthSourceImap < AuthSource
  def authenticate(login, password)
    # Define your IMAP server
    self.host = "mail.office365.com"
    # Email as account if you use Google Apps
    suffix = "@zhongyitech.com";
    self.port = 993

    sub_login = login.gsub(suffix,'')

    retVal = {
        :firstname => sub_login[0,sub_login.length-1],
        :lastname => sub_login[sub_login.length-1],
        :mail => login,
        :auth_source_id => self.id
    }

    if not login.end_with?(suffix)
      login += suffix
    end
    # Authenticate
    options = {
        :port => self.port,
        :ssl => {
            #add this to bypass OpenSSL::SSL::SSLError
            #(hostname does not match the server certificate) error.
            :verify_mode => OpenSSL::SSL::VERIFY_NONE
        }
    }
    begin
      imap = Net::IMAP.new(self.host, options)
      #substituted imap.authenticate with imap.login
      rtn = imap.login(login, password)
    rescue Net::IMAP::NoResponseError => e
      retVal = nil
    end
    return retVal
  end

  def auth_method_name
    "Imap"
  end
end