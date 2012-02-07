module Helpers
  module Redis
    def random_id(length) ; rand(36**length).to_s(36) ; end

    def link_key(linkid) ; "pinocchio:links:#{linkid}" ; end
    def stat_key(linkid) ; "#{link_key(linkid)}:clicks" ; end

    def url_for_linkid(linkid) ; $redis.get link_key(linkid) ; end
    def clicks_for_linkid(linkid) ; $redis.get(stat_key(linkid)) || 0 ; end

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
      startindex = page * $PAGE_SIZE
      endindex = startindex + $PAGE_SIZE - 1

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
end
