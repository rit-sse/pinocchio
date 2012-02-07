%w(redis app).each do |f|
  require File.expand_path("../#{f}", __FILE__)
end

module Helpers
  module All
    include Helpers::App
    include Helpers::Redis
  end
end
