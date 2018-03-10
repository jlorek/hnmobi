defmodule Hnmobi.Main.Mozilla do
  require Logger

  alias Hnmobi.Main.Sanitizer

  def get_content(url) when is_binary(url) do
    script_path = Path.join(System.cwd!(), "bin/parser/parser.js")
    shell_arguments = "node #{script_path} #{url}"

    Logger.info("Executing shell command '#{shell_arguments}'")
    parser_process = System.cmd(System.get_env("SHELL"), ["-c", shell_arguments])
    parser_output = elem(parser_process, 0)

    case Poison.decode(parser_output) do
      {:ok, json} ->
        rx_base_url = ~r/(?<base_url>http[s]*:\/\/[www\.]*[^\/]+)/
        %{"base_url" => base_url} = Regex.named_captures(rx_base_url, url)
        Sanitizer.make_img_src_absolute(json["content"], base_url)
      _ -> nil
    end
  end

  def get_content(%{:url => url} = article) do
    content = get_content(url)
    unless (is_nil(content)) do
      %{article | content: content, content_format: :html}
    else
      article
    end
  end
end
