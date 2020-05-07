defmodule Frank.Web.Plug.Bakery.Fetch do
  defmacro get_files() do
    static_files = Path.wildcard("client/dist/Frank/*.{css,js,ico,html,png,jpg,webmanifest}")

    static =
      static_files
      |> Enum.map(fn file_to_send ->
        request_path =
          file_to_send
          |> String.replace_leading("client/dist/Frank", "")

        data =
          file_to_send
          |> File.read!()

        if String.starts_with?(MIME.from_path(request_path), "text") do
          %{path: request_path, data: ~s(#{data})}
        else
          %{path: request_path, data: data}
        end
      end)

    Macro.escape(static)
  end
end

defmodule Frank.Web.Plug.Bakery do
  alias Frank.Web.Plug.Bakery.Fetch

  import Plug.Conn

  require Fetch

  require Logger

  @behaviour Plug

  files = Fetch.get_files()

  # todo:
  # - if found accept-encoding -> send .gz / .br to the client
  #
  # req_headers: [
  #     {"accept", "text/css,*/*;q=0.1"},
  #     {"accept-encoding", "gzip, deflate"},
  #     {"accept-language", "en-US,en;q=0.5"},
  #     {"cache-control", "max-age=0"},
  #     {"connection", "keep-alive"},
  #     {"host", "144.76.72.20:4040"},
  #     {"referer", "http://144.76.72.20:4040/"},
  #     {"user-agent",
  #          "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:70.0) Gecko/20100101 Firefox/70.0"}
  #   ],


  for %{path: path, data: data} <- files do
    def call(%Plug.Conn{request_path: unquote(path)} = conn, _opts) do
      conn
      |> put_resp_header("Content-Type", MIME.from_path(unquote(path)))
      |> put_resp_header("Accept-Encoding", "gzip, br")
      |> send_resp(200, unquote(data))
      |> halt()
    end

    #if path |> String.ends_with?("index.html") do
    if path == "/index.html" do
      def call(%Plug.Conn{request_path: "/"} = conn, _opts) do
        conn
        |> put_resp_header("Content-Type", MIME.from_path(unquote(path)))
        |> send_resp(200, unquote(data))
        |> halt()
      end
    end
  end

  def call(conn, _), do: conn

  def init(opts), do: opts
end
