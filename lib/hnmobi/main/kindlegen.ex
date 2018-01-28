defmodule Hnmobi.Main.Kindlegen do
  require Logger

  def convert(epub_path) do
    output_dir = Path.dirname(epub_path)
    output_file = "kindle.mobi"
    mobi_path = Path.join(output_dir, output_file)
    Logger.info("mobi_path = #{mobi_path}")

    # https://groups.google.com/forum/#!topic/elixir-lang-talk/ZrqKW1NhDCw 
    kindlegen_path = Application.fetch_env!(:hnmobi, :kindlegen_path)
    kindlegen_arguments = " #{epub_path} -o #{output_file}"
    shell_arguments = kindlegen_path <> kindlegen_arguments

    Logger.info("Executing shell command '#{shell_arguments}'")
    kindlegen_process = System.cmd(System.get_env("SHELL"), ["-c", shell_arguments])
    kindleget_output = elem(kindlegen_process, 0)
    Logger.info("<kindlegen_output>")
    Logger.info(kindleget_output)
    Logger.info("</kindlegen_output>")

    if String.contains?(kindleget_output, "Warning") do
      Logger.warn("Kindlegen executed with warning(s)")
    end

    if String.contains?(kindleget_output, "Error") do
      Logger.error("Kindlegen executed with error(s)")
    end

    if File.exists?(mobi_path) do
      {:ok, mobi_path}
    else
      {:error}
    end
  end
end
