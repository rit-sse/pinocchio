require 'sinatra/base'

class Pinocchio < Sinatra::Base
  require 'redis'
  require 'sinatra/flash'
  require File.expand_path("../helpers/all", __FILE__)

  $redis = Redis.new
  $PAGE_SIZE = 15.0

  configure do
    register Sinatra::Flash
  end

  helpers do
    include Rack::Utils
    include Helpers::All
  end

  before { @admin = !session[:user].nil?  }

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
