require 'sinatra/base'

class Pinocchio < Sinatra::Base
  require 'redis'
  require 'sinatra/flash'

  $redis = Redis.new
  PAGE_SIZE = 15.0

  configure do
    enable :sessions
    set :session_secret, "uOj0YBCsVKNMeI6xOfLXgxJYZaGLwA"

    register Sinatra::Flash
  end

  helpers do
    include Rack::Utils

    def asset_path ; request.path == '/' ? '' : request.path ; end

    def random_id(length) ; rand(36**length).to_s(36) ; end

    def link_key(linkid) ; "pinocchio:links:#{linkid}" ; end
    def stat_key(linkid) ; "#{link_key(linkid)}:clicks" ; end

    def url_for_linkid(linkid) ; $redis.get link_key(linkid) ; end
    def clicks_for_linkid(linkid) ; $redis.get(stat_key(linkid)) || 0 ; end

    def url_for_paginated_page(page)
      the_url = "/?page=#{page}"
    end
    def prev_page_url
      return "#" if prev_page_url_disabled?
      url_for_paginated_page(params[:page].to_i - 1)
    end
    def next_page_url
      return "#" if next_page_url_disabled?
      return url_for_paginated_page(params[:page].to_i + 1) if params[:pgae].to_i != 0
      url_for_paginated_page(2)
    end
    def prev_page_url_disabled?
      (0..1).include? params[:page].to_i
    end
    def next_page_url_disabled?
      params[:page].to_i == (@link_count / PAGE_SIZE).ceil || @link_count <= PAGE_SIZE
    end
    def page_url_disabled?(index)
      params[:page].to_i == index || (params[:page].to_i == 0 && index == 1)
    end
    def paginate
      @link_count ||= link_count

      (1..(@link_count / PAGE_SIZE).ceil).each do |i|
        yield i if block_given?
      end
    end
    def link_count
      if @admin
        @link_count = $redis.llen "pinocchio:alllinks"
      else
        @link_count = session[:links].to_s.split(',').length
      end
    end
    def get_links
      page = params[:page].to_i
      page -= 1 if page >= 1
      startindex = page * PAGE_SIZE
      endindex = startindex + PAGE_SIZE - 1

      if @admin
        $redis.lrange "pinocchio:alllinks", startindex, endindex
      else
        session[:links].to_s.split(',').reverse[startindex..endindex]
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
      $redis.lpush "pinocchio:alllinks", linkid
    end
    def remove_link(linkid)
      $redis.del "pinocchio:links:#{params[:linkid]}"
      $redis.lrem "pinocchio:alllinks", 0, params[:linkid]
      session[:links].gsub! linkid, ''
      session[:links].gsub! /[,]+/, ','
      session[:links].gsub! /^[,]+/, ''
      session[:links].gsub! /[,]+$/, ''
    end
  end

  before { @admin = !request.cookies['_wtf_authenticated'].nil?  }

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
      redirect url('/')
    end
  end

  post '/:linkid' do
    remove_link params[:linkid]
    flash[:success] = "Shortlink deleted."
    redirect url("/")
  end
end
