defmodule ShortUrlWeb.PageControllerTest do
  use ShortUrlWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "STORD URL Shortener Exercise"
  end

  describe "POST /" do
    test "Successfully submit new URL", %{conn: conn} do
      {conn, _} = post_valid_url(conn)
      assert html_response(conn, 200) =~ "Your shortened url is:"
    end

    test "Submit otherwise valid URL without path", %{conn: conn} do
      conn = post(conn, :new_url, %{"URL" => "https://www.google.com"})
      assert html_response(conn, 200) =~ "URLs must start with: http(s)://{domain}/"
    end

    test "Submit otherwise valid URL without scheme", %{conn: conn} do
      conn = post(conn, :new_url, %{"URL" => "www.google.com/"})
      assert html_response(conn, 200) =~ "URLs must start with: http(s)://{domain}/"
    end

    test "Keys should be identical if same url is submitted twice", %{conn: conn} do
      {conn, url} = post_valid_url(conn)
      %{"key" => first_key} = capture_key(conn)
      conn = post(conn, :new_url, %{"URL" => url})
      %{"key" => second_key} = capture_key(conn)
      assert first_key == second_key
    end
  end

  describe "GET /:key" do
    test "Successfully submit valid key", %{conn: conn} do
      {conn, url} = post_valid_url(conn)
      %{"key" => key} = capture_key(conn)
      conn = get(conn, "/#{key}")
      assert html_response(conn, 302) =~ "href=\"#{url}\""
    end

    test "Successfully submit invalid key", %{conn: conn} do
      conn = get(conn, "/123456")
      assert html_response(conn, 200) =~ "Key not found."
    end
  end

  def post_valid_url(conn) do
    url = "https://www.google.com/search?q=#{Enum.random(100_000..999_999)}"
    conn = post(conn, :new_url, %{"URL" => url})
    {conn, url}
  end

  defp capture_key(conn), do: Regex.named_captures(~r/\/(?<key>.{6})<\/a>/, html_response(conn, 200))
end
