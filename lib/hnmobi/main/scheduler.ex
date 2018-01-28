defmodule Hnmobi.Main.Scheduler do
  use Quantum.Scheduler, otp_app: :hnmobi
  require Logger
  alias Hnmobi.Main.Ebook
  alias Hnmobi.Users
  alias Hnmobi.Users.User
  alias Hnmobi.Main.Mailer
  alias Hnmobi.Main.UserEmail

  def heartbeat() do
    Logger.info("'Every minute i'm hustlin.' -- Scheduler")
  end

  def send_daily() do
    Logger.info("Daily deliver started")
    {:ok, mobi_path} = Ebook.generate_top()

    Enum.each(Users.get_daily_recipients(), fn kindle_email ->
      UserEmail.compose_daily(mobi_path, kindle_email) |> Mailer.deliver()
    end)
  end

  def send_weekly() do
    Logger.info("Weekly delivery started")
  end
end
