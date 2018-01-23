defmodule Hnmobi.Main.Mailer do
  use Swoosh.Mailer, otp_app: :hnmobi
end

defmodule Hnmobi.Main.LoginEmail do
  import Swoosh.Email
  require Logger

  def deliver(test) do
    Logger.info "Composing LOGIN mail for '#{test.user.email}''"

    new()
    |> to(test.user.email)
    |> from("delivery@hackernews.mobi")
    |> subject("Your Login Link for hackernews.mobi")
    |> html_body("<h3>Your login link: <a href=\"#{test.link}\">Login</a></h3>")
    |> text_body("Your login link: #{test.link}")
  end
end

defmodule Hnmobi.Main.UserEmail do
  require Logger
  import Swoosh.Email

  def compose_daily(mobi_file, email) do
    Logger.info "Composing mail for '#{email}''"

    new()
    |> to(email)
    |> from("delivery@hackernews.mobi")
    |> subject("your daily hackernews.mobi delivery")
    |> html_body("<h1>Enjoy your read</h1>")
    |> text_body("Enjoy your read\n")
    |> attachment(mobi_file)
  end
  
  def compose_single(title, mobi_file, email) do
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