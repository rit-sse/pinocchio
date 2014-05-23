require 'rubygems'
require 'bundler'

Bundler.require

require './app.rb'
require 'rack'
require 'rack/session/redis'

map "/go" do
  secret_file_path = '/events/session_key'
  secret_key = "Ouppvx4UKRIJ7zHCDuFEYh7IOwaJ3dIClmROlIzj5Y5RkSVeN2CIZMOar6FxwYL"
  if File.exist? secret_file_path
    secret_key = File.read(secret_file_path).chomp
  end
  use Rack::Session::Redis, key: "_sse_session",
                            secret: secret_key,
                            key_prefix: "sse:session:"
  run Pinocchio
end