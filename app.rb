require 'sinatra/base'
require 'rack/csrf'

class Pinocchio < Sinatra::Base
  require 'redis'
  require 'sinatra/flash'
  require File.expand_path("../helpers/all", __FILE__)
  enable :sessions

  $redis = Redis.new
  $PAGE_SIZE = 15

  configure do
    register Sinatra::Flash
    use Rack::Csrf, :raise => true
  end

  helpers do
    include Rack::Utils
    include Helpers::All

    def csrf_tag
      Rack::Csrf.csrf_tag(env)
    end
  end

  get "/" do
    erb :index
  end

  post "/auth" do
    if ENV['RACK_ENV'] == 'development' and
      params[:username] == "admin" and
      params[:password] == "admin"

      set_current_user "admin", "admin"

      fl[:success] = "Logged in successfully."
      redirect url("/")
    else
      username = params[:username]
      username = username[/\A\w+/].downcase
      user = username + "@ad.sofse.org"
      psw = params[:password]
      authorized = false

      ldap = Net::LDAP.new host: "dc1.ad.sofse.org",
           port: 389,
           auth: {
                 method: :simple,
                 username: user,
                 password: psw
           }

      filter = Net::LDAP::Filter.eq("mail", "*")
      treebase = "OU=Officers,OU=Users,OU=SOFSE,DC=ad,DC=sofse,DC=org"

      officers = []
      ldap.search(base: treebase, filter: filter) do |entry|
        officers << entry.mail.first.split("@").first
      end

      if officers.include?(username)
        authorized = true
      end

      error_notice = nil

      if authorized

        username = user
        role = "admin"

        set_current_user username, role
        fl[:success] = "Logged in successfully."
        redirect url("/")
      else
        if ldap
          error_notice = "Insufficient Privileges"
        else
          error_notice = "Error: #{ldap.get_operation_result.message}"
        end
      end

      if error_notice
        fl[:error] = error_notice
        erb :index
      end
    end
  end

  post '/logout' do
    session.clear
    fl[:success] = "Logged out successfully"
    redirect url('/')
  end

  post '/' do
    if signed_in?
      if !params[:name].to_s.empty?
        fl.now[:error] = "Stop spamming"
      else

        unless params[:url].to_s.empty?
          full_url = params[:url].strip
          valid_id = true

          # grab or generate link id
          unless params[:vanityname].to_s.empty?
            linkid = params[:vanityname].strip

            # validate vanity names
            valid_id = linkid.match /^[\w-]+$/i
          else
            linkid = random_id 5
          end

          if valid_id
            # set if key doesn't already exist
            result = $redis.setnx link_key(linkid), full_url

            if result
              # add link to session
              add_link linkid
              fl.now[:success] = "Shortlink created."
            else
              fl.now[:error] = "Key already exists. Make sure your vanity name is unique."
            end
          else
            fl.now[:error] = "Invalid vanity name. Must contain only alphanumeric characters, dashes, and underscores."
          end
        end

      end
    else
      fl.now[:error] = "You must be logged in"
    end
    erb :index
  end

  get '/:linkid' do
    @url = url_for_linkid params[:linkid]

    if @url
      $redis.incr stat_key(params[:linkid])
      redirect @url
    else
      fl[:error] = "Oops - doesn't look like that link exists."
      redirect url('/')
    end
  end

  post '/:linkid/delete' do
    if signed_in?
      remove_link params[:linkid]
      fl[:success] = "Shortlink deleted."
    end

    redirect url("/")
  end
end
