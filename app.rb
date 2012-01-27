class Pinocchio < Sinatra::Base
  $redis = Redis.new

  configure do
    enable :sessions
    set :session_secret, "uOj0YBCsVKNMeI6xOfLXgxJYZaGLwA"
    register Sinatra::Flash
  end

  helpers do
    include Rack::Utils

    def random_id(length) ; rand(36**length).to_s(36) ; end

    def link_key(linkid) ; "pinocchio:links:#{linkid}" ; end
    def stat_key(linkid) ; "#{link_key(linkid)}:clicks" ; end

    def url_for_linkid(linkid) ; $redis.get link_key(linkid) ; end
    def clicks_for_linkid(linkid) ; $redis.get(stat_key(linkid)) || 0 ; end

    def get_links
      if params[:all] == "true"
        ($redis.lrange "pinocchio:alllinks", 0, -1) || []
      else
        session[:links].to_s.split(',').reverse
      end
    end
    def add_link(linkid)
      # add link to session
      unless session[:links].to_s.empty?
        session[:links] << ",#{linkid}"
      else
        session[:links] = linkid
      end

      # add link to pinochio collection
      $redis.rpush "pinocchio:alllinks", linkid
    end
  end

  get "/" do
    erb :index
  end

  post '/' do
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
          flash.now[:success] = "Shortlink created."
        else
          flash.now[:error] = "Key already exists. Make sure your vanity name is unique."
        end
      else
        flash.now[:error] = "Invalid vanity name. Must contain only alphanumeric characters, dashes, and underscores."
      end
    end

    erb :index
  end

  get '/:linkid' do
    @url = url_for_linkid params[:linkid]

    if @url
      $redis.incr stat_key(params[:linkid])
      redirect @url
    else
      flash[:error] = "Oops - doesn't look like that link exists."
      redirect '/'
    end
  end
end
