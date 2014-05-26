%w(redis app auth).each do |f|
  require File.expand_path("../#{f}", __FILE__)
end

module Helpers
  module All
    include Helpers::Auth
    include Helpers::App
    include Helpers::Redis
  end
end
