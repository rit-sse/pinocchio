module Helpers
  module Auth
    def current_user
      unless session[:user].nil?
        @current_user ||= session[:user]
      end

      @current_user
    end

    def set_current_user(username, role)
      user = {username: username, role: role}
      session[:user] = user
      @current_user = user
    end

    def signed_in?
      not current_user.nil?
    end
  end
end