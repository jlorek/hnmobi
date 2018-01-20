defmodule HnmobiWeb.LayoutView do
  use HnmobiWeb, :view

  # https://stackoverflow.com/a/31577025/1010496
  def active_class(conn, path) do
    current_path = Path.join(["/" | conn.path_info])
    if path == current_path do
      "active"
    else
      nil
    end
  end
end
