require "sinatra"
require "sinatra/reloader"
# require "sinatra/content_for"
require "tilt/erubis"
require "redcarpet"

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

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    render_markdown(content)
  end
end

get "/:filename" do
  filename = params[:filename]
  path = root + "/data/" + filename
  if File.exist?(path)
    load_file_content(path)
  else
    session[:message] = "#{filename} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  @filename = params[:filename]
  path = root + "/data/" + @filename
  @content = File.read(path)
  erb :edit
end

post "/:filename" do
  filename = params[:filename]
  path = root + "/data/" + filename
  File.write(path, params[:content])
  session[:message] = "#{filename} has been updated."
  redirect "/"
end
