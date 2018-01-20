defmodule Hnmobi.Main.Mailer do
  use Swoosh.Mailer, otp_app: :hnmobi
end

defmodule Hnmobi.Main.UserEmail do
  require Logger
  import Swoosh.Email

  def deliver(title, mobi_file, email) do
    Logger.info "Composing mail for '#{email}''"

    new()
    |> to(email)
    |> from("delivery@hackernews.mobi")
    |> subject("Fresh delivery - #{title}")
    |> html_body("<h1>Enjoy your read</h1>")
    |> text_body("Enjoy your read\n")
    |> attachment(mobi_file)
  end

  def test(email) do
    new()
    |> to(email)
    |> from("delivery@hackernews.mobi")
    |> subject("Test Mail")
    |> html_body("<h1>hello mail</h1>")
    |> text_body("hello mail\n")
  end
end