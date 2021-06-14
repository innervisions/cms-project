require "sinatra"
require "sinatra/reloader" if development?
# require "sinatra/content_for"
# require "tilt/erubis"

configure do
  # set :erb, escape_html: true
  # enable :sessions
  # set :session_secret, "secret"
  set :port, 8080
end

get "/" do
  "Getting started"
end
