defmodule HnmobiWeb.DebugController do
  require Logger
  use HnmobiWeb, :controller

  alias Hnmobi.Main.UserEmail
  alias Hnmobi.Main.Mailer
  alias Hnmobi.Main.Ebook

  alias Hnmobi.Users

  def index(conn, _params) do
    render conn, "index.html"
  end

  def show(conn, _params) do
    # value = Timex.now |> Timex.format!("{D}. {Mfull} '{YY}")
    # value = Timex.now |> Timex.to_unix
    # value = Enum.join(Users.get_daily_recipients, ", ")
    # value = System.cwd!()
    value = Path.join(System.cwd!(), "pandoc/static/cover.jpg")
    render conn, "show_value.html", value: value
  end

  def download(conn, _params) do
    {:ok, mobi_path} = Ebook.generate_top()
    timestamp = Timex.now |> Timex.to_unix    

    conn
    |> put_resp_content_type("application/octet-stream", nil)
    |> put_resp_header("content-disposition", ~s[attachment; filename="hnmobi-#{timestamp}.mobi"])
    |> send_file(200, mobi_path)
  end

  def send_email(conn, %{"email" => email}) do
    UserEmail.compose_test(email) |> Mailer.deliver()

    conn
    |> put_flash(:info, "Mail sent to " <> email)
    |> redirect(to: "/debug")
  end
end