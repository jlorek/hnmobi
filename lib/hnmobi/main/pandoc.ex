defmodule Hnmobi.Main.Pandoc do
  require Logger

  alias Hnmobi.Main.Article

  defp cover_path() do
    Path.join(System.cwd!(), "pandoc/static/cover.jpg")
  end

  defp get_pandoc_path() do
    Application.fetch_env!(:hnmobi, :pandoc_path)
  end

  defp execute_shell(shell_arguments) do
    Logger.info("Executing shell command '#{shell_arguments}'")
    pandoc_process = System.cmd(System.get_env("SHELL"), ["-c", shell_arguments])
    pandoc_output = elem(pandoc_process, 0)
    Logger.info("<pandoc_output>")
    Logger.info(pandoc_output)
    Logger.info("</pandoc_output>")

    if String.contains?(pandoc_output, "WARNING") do
      Logger.warn("Pandoc executed with warning(s)")
    end
  end

  def convert_from_markdown(md_path) do
    {:ok, working_directory} = Temp.mkdir
    html_path = Path.join(working_directory, "readme.html")

    pandoc_arguments = " --verbose -f gfm -t html -o #{html_path} #{md_path}"
    shell_arguments = get_pandoc_path() <> pandoc_arguments
    execute_shell(shell_arguments)

    html_path
  end

  def convert(working_directory, files) do
    epub_path = Path.join(working_directory, "pandoc.epub")
    Logger.info("epub_path = #{epub_path}")

    cover_path = cover_path()
    Logger.info("cover_path = #{cover_path}")

    unless File.exists?(cover_path) do
      Logger.warn("Cover image should be located at '#{cover_path}' but could not be found")
    end

    input_files = Enum.join(files, " ")

    pandoc_arguments =
      " --verbose -s -f html -t epub --epub-cover-image=#{cover_path} -o #{epub_path} #{input_files}"

    shell_arguments = get_pandoc_path() <> pandoc_arguments

    execute_shell(shell_arguments)
    {:ok, epub_path}
  end

  defp prepare_html(article, debug \\ false) do

    unless is_nil(content) do
      case Temp.path %{suffix: ".html"} do
        {:ok, html_path } ->
          Logger.info "html_path = #{html_path}"
          case File.open html_path, [:write, :utf8] do
            {:ok, html_handle} ->
              if debug, do: add_debug_page(html_handle, article)
              # https://www.w3schools.com/cssref/pr_print_pagebb.asp
              IO.write html_handle, "<a name=\"#{id}\"></a>"
              IO.write html_handle, "<h1 style=\"page-break-before:always\">#{title}</h1>"
              IO.write html_handle, content
              File.close html_handle
              %{ article | html_path: html_path }
            _ ->
              Logger.error "Could not open html article file"
              nil
          end
        _ ->
          Logger.error "Could not generate html article path"
          nil
      end
    else
      nil
    end
  end
end
