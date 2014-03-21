require 'rubygems'
require 'bundler'

Bundler.require

require './app.rb'

map "/go" do
  secret_file_path = ::File.expand_path('/events/session_key', __FILE__)
  secret_key = "Ouppvx4UKRIJ7zHCDuFEYh7IOwaJ3dIClmROlIzj5Y5RkSVeN2CIZMOar6FxwYL"
  if File.exist? secret_file_path
    secret_key = File.read secret_file_path
  end
  use Rack::Session::Cookie, key: "_sse_session",
                             secret: secret_key

  run Pinocchio
end