module Helpers
  module App
    # pagination

    def url_for_paginated_page(page)
      url "/?page=#{page}"
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
      params[:page].to_i == (@link_count / $PAGE_SIZE).ceil || @link_count <= $PAGE_SIZE
    end

    def page_url_disabled?(index)
      params[:page].to_i == index || (params[:page].to_i == 0 && index == 1)
    end

    def paginate
      @link_count ||= link_count

      (1..(@link_count / $PAGE_SIZE).ceil).each do |i|
        yield i if block_given?
      end
    end
  end
end
