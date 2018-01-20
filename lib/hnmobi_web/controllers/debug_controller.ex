defmodule HnmobiWeb.DebugController do
  require Logger
  use HnmobiWeb, :controller

  alias Hnmobi.Main.Ebook

  def index(conn, _params) do
    render conn, "index.html"
  end

  def show(conn, _params) do
    # value = Timex.now |> Timex.format!("{D}. {Mfull} '{YY}")
    value = Timex.now |> Timex.to_unix
    render conn, "show_value.html", value: value
  end

  def download(conn, _params) do
    mobi_path = Ebook.generate
    filename = Timex.now |> Timex.to_unix    

    conn
    |> put_resp_content_type("application/octet-stream", nil)
    |> put_resp_header("content-disposition", ~s[attachment; filename="#{filename}.mobi"])
    |> send_file(200, mobi_path)
  end
end