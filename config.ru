require 'rubygems'
require 'bundler'

Bundler.require

require './app.rb'

secret_file_path = "#{root}/../session_key"
secret_key = "Ouppvx4UKRIJ7zHCDuFEYh7IOwaJ3dIClmROlIzj5Y5RkSVeN2CIZMOar6FxwYL"
if File.exist? secret_file_path
  secret_key = File.read secret_file_path
end
use Rack::Session::Cookie, key: "_sse_session",
                           secret: secret_key

run Pinocchio

