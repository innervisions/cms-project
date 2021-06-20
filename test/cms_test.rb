ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_match "about.md", last_response.body
    assert_match "changes.txt", last_response.body
    assert_match "history.txt", last_response.body
  end

  def test_viewing_text_document
    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_match "1993 - Yukihiro Matsumoto dreams up Ruby.", last_response.body
    assert_match "2007 - Ruby 1.9 released.", last_response.body
    assert_match "2019 - Ruby 2.7 released.", last_response.body
  end

  def test_document_not_found
    get "/hellokitty.txt"
    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "hellokitty.txt does not exist"

    get "/"
    refute_includes last_response.body, "hellokitty.txt does not exist"
  end

  def test_viewing_markdown_document
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby</h1>"
  end

  def test_editing_document
    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, '<button type="submit"'
  end

  def test_updating_document
    post "/changes.txt", content: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end
end
