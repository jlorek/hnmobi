defmodule Hnmobi.Main.Mozilla do
  require Logger

  def get_content(url) do
    script_path = Path.join(System.cwd!(), "bin/parser/parser.js")
    shell_arguments = "node #{script_path} #{url}"

    Logger.info("Executing shell command '#{shell_arguments}'")
    parser_process = System.cmd(System.get_env("SHELL"), ["-c", shell_arguments])
    parser_output = elem(parser_process, 0)
    %{"content" => content} = Poison.decode!(parser_output)
    content
  end
end
