ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { username: "admin" } }
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_viewing_text_document
    create_document "changes.txt", "added new content."
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "added new content."
  end

  def test_document_not_found
    get "/hellokitty.txt"
    assert_equal 302, last_response.status
    assert_equal "hellokitty.txt does not exist.", session[:message]
  end

  def test_viewing_markdown_document
    create_document "about.md", "#Ruby"
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby</h1>"
  end

  def test_editing_document
    create_document "changes.txt", "Some random text."
    get "/changes.txt/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_editing_document_signed_out
    create_document "changes.txt", "Some random text."
    get "/changes.txt/edit"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_updating_document
    post "/changes.txt", { content: "new content" }, admin_session

    assert_equal 302, last_response.status
    assert_equal "changes.txt has been updated.", session[:message]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_updating_document_signed_out
    post "/changes.txt", { content: "new content" }

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_view_new_document_form
    get "/new", {}, admin_session
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, '<button type="submit'
  end

  def test_view_new_document_form_signed_out
    get "/new"
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_create_new_document
    post "/create", { filename: "test.txt" }, admin_session
    assert_equal 302, last_response.status
    assert_equal "test.txt has been created.", session[:message]

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_without_filename
    post "/create", { filename: "" }, admin_session
    assert_equal 422, last_response.status

    assert_includes last_response.body, "A name is required."
  end

  def test_create_new_document_with_invalid_extension
    post "/create", { filename: "hello.exe" }, admin_session
    assert_equal 422, last_response.status

    assert_includes last_response.body, "Please choose a valid extension."
  end

  def test_create_new_document_signed_out
    post "/create", { filename: "test.txt" }
    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]
  end

  def test_delete_document
    create_document "testdoc.txt", "some content"

    post "/testdoc.txt/delete", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "testdoc.txt was deleted.", session[:message]
  end

  def test_delete_document_signed_out
    create_document "testdoc.txt", "some content"
    post "/testdoc.txt/delete"

    assert_equal 302, last_response.status
    assert_equal "You must be signed in to do that.", session[:message]

    get "/"
    assert_includes last_response.body, "testdoc.txt"
  end

  def test_signin_form
    get "/users/signin"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_signin
    post "/users/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    assert_equal "Welcome!", session[:message]
    assert_equal "admin", session[:username]

    get last_response["Location"]
    assert_includes last_response.body, "Signed in as admin"
  end

  def test_signin_with_bad_credentials
    post "/users/signin", username: "admin", password: "seacrest"
    assert_equal 422, last_response.status
    assert_nil session[:username]
    assert_includes last_response.body, "Invalid Credentials"
  end

  def test_signout
    post "/users/signin", username: "admin", password: "secret"
    assert_equal "Welcome!", session[:message]

    post "/users/signout"
    assert_equal "You have been signed out.", session[:message]
    get last_response["Location"]

    assert_includes last_response.body, "Sign In"
  end
end
