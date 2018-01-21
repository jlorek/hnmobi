defmodule Hnmobi.Main.Scheduler do
  require Logger
  use Quantum.Scheduler, otp_app: :hnmobi

  def heartbeat() do
    Logger.info "'Every minute i'm hustlin.' -- Scheduler"
  end

  def send_daily() do
    Logger.info "Daily deliver started"
  end

  def send_weekly() do
    Logger.info "Weekly delivery started"
  end

end