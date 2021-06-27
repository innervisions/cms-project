require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "redcarpet"
require "yaml"
require "bcrypt"

configure do
  # set :erb, escape_html: true
  enable :sessions
  set :session_secret, 'super secret'
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path('test/data', __dir__)
  else
    File.expand_path('data', __dir__)
  end
end

def create_document(name, content = "")
  File.open(File.join(data_path, name), "w") do |file|
    file.write(content)
  end
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  return if user_signed_in?
  session[:message] = "You must be signed in to do that."
  redirect "/"
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index
end

get "/new" do
  require_signed_in_user
  erb :new
end

def invalid_extension?(filename)
  valid_extensions = ["txt", "md"]
  !valid_extensions.include?(filename.split(".").last)
end

post "/create" do
  require_signed_in_user
  filename = params[:filename]
  if filename.empty?
    status 422
    session[:message] = "A name is required."
    erb :new
  elsif invalid_extension?(filename)
    status 422
    session[:message] = "Please choose a valid extension."
    erb :new
  else
    create_document(filename, "")
    session[:message] = "#{filename} has been created."
    redirect "/"
  end
end

get "/users/signin" do
  erb :signin
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
                       File.expand_path('test/users.yml', __dir__)
                     else
                       File.expand_path('users.yml', __dir__)
                     end
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_user_credentials
  return false unless credentials.key?(username)
  hashed_pass = BCrypt::Password.new(credentials[username])
  hashed_pass == password
end

post "/users/signin" do
  if valid_credentials?(params[:username], params[:password])
    session[:username] = params[:username]
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid Credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
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
    erb render_markdown(content)
  end
end

get "/:filename" do
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{filename} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  require_signed_in_user
  @filename = params[:filename]
  file_path = File.join(data_path, @filename)
  @content = File.read(file_path)
  erb :edit
end

post "/:filename" do
  require_signed_in_user
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  File.write(file_path, params[:content])
  session[:message] = "#{filename} has been updated."
  redirect "/"
end

post "/:filename/delete" do
  require_signed_in_user
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  File.delete(file_path)
  session[:message] = "#{filename} was deleted."
  redirect "/"
end

def generate_duplicate_name(file_path)
  idx = 1
  extension = File.extname(file_path)
  base_name = File.basename(file_path, ".*")
  duplicate_name = nil
  loop do
    duplicate_name = "#{base_name} dup#{idx}#{extension}"
    break unless File.exist?(File.join(data_path, duplicate_name))
    idx += 1
  end
  duplicate_name
end

post "/:filename/duplicate" do
  require_signed_in_user
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  duplicate_name = generate_duplicate_name(file_path)
  content = File.read(file_path)
  create_document(duplicate_name, content)
  session[:message] = "#{filename} has been duplicated."
  redirect "/"
end
