require "sinatra"
require "sinatra/reloader"
# require "sinatra/content_for"
require "tilt/erubis"

configure do
  # set :erb, escape_html: true
  enable :sessions
  set :session_secret, 'super secret'
end

root = File.expand_path(__dir__)

get "/" do
  @files = Dir.glob(root + "/data/*").map do |path|
    File.basename(path)
  end
  erb :index
end

get "/:filename" do
  path = root + "/data/" + params[:filename]
  if File.file?(path)
    headers["Content-Type"] = "text/plain"
    File.read(path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end
