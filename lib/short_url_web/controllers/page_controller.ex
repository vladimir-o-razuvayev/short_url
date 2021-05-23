defmodule ShortUrlWeb.PageController do
  use ShortUrlWeb, :controller

  import Phoenix.HTML.Link

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def new_url(conn, %{"URL" => url}) do
    if valid?(url) do
      case attempt(url) do
        {:ok, key} -> render_success(conn, key)
        _ -> render_failure(conn)
      end
    else
      render_invalid_url(conn)
    end
  end

  def key(conn, %{"key" => key}) do
    case :dets.lookup(:store, key) do
      [{_, url}] -> redirect(conn, external: url)
      _ -> render_invalid_key(conn)
    end
  end

  defp render_success(conn, key) do
    short_url = ShortUrlWeb.Endpoint.url() <> "/" <> key
    conn
    |> put_flash(:info, ["Your shortened url is: ", link(short_url, to: short_url)])
    |> render("index.html")
  end

  defp render_failure(conn) do
    conn
    |> put_flash(:error, "Something went wrong.")
    |> render("index.html")
  end

  defp render_invalid_key(conn) do
    conn
    |> put_flash(:error, "Key not found.")
    |> render("index.html")
  end

  defp render_invalid_url(conn) do
    conn
    |> put_flash(:error, "URLs must start with: http(s)://{domain}/")
    |> render("index.html")
  end

  defp encode(url), do: :crypto.hash(:md5, url) |> Base.encode64() |> String.slice(0..5) |> String.replace("/", "-")

  defp attempt(url) do
    key = encode(url)
    case :dets.lookup(:store, key) do
      [] -> if :dets.insert(:store, {key, url}), do: {:ok, key}, else: :error
      [{_, old_url}] -> if old_url == url, do: {:ok, key}, else: attempt(url <> "#" <> Enum.random(1000..9999))
    end
  end

  defp valid?(url) do
     %URI{authority: _, fragment: _, host: host, path: path, port: port, query: _, scheme: scheme, userinfo: _} = URI.parse(url)
     Enum.all?([host, path, port, scheme], &(&1 != nil))
  end
end
