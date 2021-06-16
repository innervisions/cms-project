require "sinatra"
require "sinatra/reloader"
# require "sinatra/content_for"
require "tilt/erubis"

configure do
  # set :erb, escape_html: true
  # enable :sessions
  # set :session_secret, "secret"
  set :port, 8080
end

root = File.expand_path(__dir__)

get "/" do
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :index
end

get "/:file_name" do
  path = root + "/data/" + params[:file_name]
  headers["Content-Type"] = "text/plain"
  File.read(path)
end
