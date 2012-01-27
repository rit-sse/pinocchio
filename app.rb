class Pinocchio < Sinatra::Base
  $redis = Redis.new

  configure do
    enable :sessions
    set :session_secret, "uOj0YBCsVKNMeI6xOfLXgxJYZaGLwA"
    register Sinatra::Flash
  end

  helpers do
    include Rack::Utils

    def random_id(length)
      rand(36**length).to_s(36)
    end

    def rkey(linkid)
      "pinocchio:links:#{linkid}"
    end

    def url_for_linkid(linkid)
      $redis.get rkey(linkid)
    end

    def get_links
      session[:links].to_s.split(',')
    end

    def add_link(linkid)
      unless session[:links].to_s.empty?
        session[:links] << ",#{linkid}"
      else
        session[:links] = linkid
      end
    end
  end

  get "/" do
    erb :index
  end

  post '/' do
    unless params[:url].to_s.empty?
      full_url = params[:url].strip

      unless params[:vanityname].to_s.empty?
        linkid = params[:vanityname].strip
      else
        linkid = random_id 5
      end

      result = $redis.setnx rkey(linkid), full_url

      if result
        add_link linkid
        flash.now[:success] = "Shortlink created."
      else
        flash.now[:error] = "Key already exists. Make sure your vanity name is unique."
      end
    end
    erb :index
  end

  get '/:linkid' do
    @url = url_for_linkid params[:linkid]
    redirect @url || '/'
  end
end
