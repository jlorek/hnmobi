defmodule Hnmobi.Main.Ebook do
  require Logger

  alias Hnmobi.Main.Mercury
  alias Hnmobi.Main.HackerNews
  
  def generate do
    Logger.info "Starting ebook generation..."

    {:ok, temp_path} = Temp.mkdir

    articles = HackerNews.top
    |> Enum.map(&prepare_html/1)
    # pre filter like .pdf
    # and create link list?
    # open graph tags parsen
    |> Enum.filter(fn result -> not is_nil result end)
    
    toc_path = prepare_toc Enum.map(articles, fn article -> article.meta end)

    html_paths = Enum.map(articles, fn result -> result.html_path end)
    html_paths = [prepare_header |[toc_path | html_paths]] ++ [prepare_footer]
    
    epub_path = prepare_single_epub temp_path, html_paths
    mobi_path = prepare_mobi epub_path

    Logger.info "...ebook generation completed!"
    mobi_path
  end

  defp prepare_html(%{"url" => url, "title" => title} = meta) do
    content = Mercury.reader(url)
    unless is_nil content do
      {:ok, html_path } = Temp.path %{suffix: ".html"}
      Logger.info "html_path = #{html_path}"
      
      {:ok, html_handle} = File.open html_path, [:write, :utf8]
      # https://www.w3schools.com/cssref/pr_print_pagebb.asp
      IO.write html_handle, "<h1 style=\"page-break-before:always\">#{title}</h1>"
      IO.write html_handle, "<p>Source: <a href=\"#{url}\">#{url}</a></p>"
      IO.write html_handle, "<img src=\"http://www.mustacheridesla.com/mustache.png\" />"
      IO.write html_handle, content
      File.close html_handle
      %{ meta: meta, html_path: html_path }
    else
      nil
    end
  end

  defp prepare_html(article) do
    Logger.warn "Article has missing 'url' or 'title'"
    nil
  end

  defp prepare_header() do
      html_path = Temp.path! %{suffix: ".html"}
      Logger.info "header_path = #{html_path}"

      current_time = Timex.now
      timestamp = current_time |> Timex.to_unix
      date = current_time |> Timex.format!("{D}. {Mfull} '{YY}")
      time = current_time |> Timex.format!("{h24}:{m}:{s}")
      
      {:ok, html_handle} = File.open html_path, [:write, :utf8]

      case File.open html_path, [:write, :utf8] do
        {:ok, html_handle} ->
          IO.write html_handle, "<html><head><title>hackernews.mobi ##{timestamp}</title></head><body>"
          IO.write html_handle, "<h1>hackernews.mobi</h1>"
          IO.write html_handle, "<img src=\"https://t2.rbxcdn.com/fe91a04c36cb2552ea36e4cf36598264\" />"
          IO.write html_handle, "<h3>Issue #{date}</h3>"
          IO.write html_handle, "<h3>Generated at #{time} (UTC)</h3>"
          File.close html_handle
          html_path
        _ ->
          Logger.error "Could not generate header html"
          nil
      end
  end

  defp prepare_toc(articles) do
    html_path = Temp.path! %{suffix: ".html"}
    Logger.info "toc_path = #{html_path}"
    
    {:ok, html_handle} = File.open html_path, [:write, :utf8]
    IO.write html_handle, "<h1 style=\"page-break-before:always\">Articles</h1>"
    Enum.each articles, &IO.write(html_handle, "<h2>#{&1["title"]}</h2>")
    File.close html_handle
    html_path
  end

  defp prepare_footer() do
    html_path = Temp.path! %{suffix: ".html"}
    Logger.info "footer_path = #{html_path}"
    
    {:ok, html_handle} = File.open html_path, [:write, :utf8]
    IO.write html_handle, "</body></html>"
    File.close html_handle
    html_path
  end

  defp prepare_single_epub(temp_path, htmls) do
    epub_path = Path.join(temp_path, "pandoc.epub")
    Logger.info "epub_path = #{epub_path}"
    
    input_files = Enum.join(htmls, " ");
    pandoc_path = Application.fetch_env!(:hnmobi, :pandoc_path)
    pandoc_arguments = " -s -f html -t epub -o #{epub_path} #{input_files}"
    shell_arguments = pandoc_path <> pandoc_arguments
    Logger.info "Executing shell command '#{shell_arguments}'"
    pandoc_process = System.cmd System.get_env("SHELL"), ["-c", shell_arguments]
    pandoc_output = elem(pandoc_process, 0)
    Logger.info pandoc_output

    if String.contains?(pandoc_output, "WARNING") do
        Logger.warn "Pandoc was not pleased but did the job!"
    end

    epub_path
  end

  defp prepare_epub(html_path) do
    epub_path = Temp.path! %{suffix: ".epub"}
    Logger.info "epub_path = #{epub_path}"
    
    # process_padoc = System.cmd "pandoc", ["-s", "-f html", "-t epub", "-o #{epub_path}", html_path]
    pandoc_path = Application.fetch_env!(:hnmobi, :pandoc_path)
    pandoc_arguments = " -s -f html -t epub -o #{epub_path} #{html_path}"
    shell_arguments = pandoc_path <> pandoc_arguments
    Logger.info "Executing shell command '#{shell_arguments}'"
    pandoc_process = System.cmd System.get_env("SHELL"), ["-c", shell_arguments]
    pandoc_output = elem(pandoc_process, 0)
    Logger.info pandoc_output

    if String.contains?(pandoc_output, "WARNING") do
        Logger.warn "Pandoc was not pleased but did the job!"
    end

    epub_path
  end

  defp prepare_mobi(epub_path) do
    mobi_path = Path.join(Path.dirname(epub_path), "kindle.mobi")
    Logger.info "mobi_path = #{mobi_path}"

    # https://groups.google.com/forum/#!topic/elixir-lang-talk/ZrqKW1NhDCw 
    kindlegen_path = Application.fetch_env!(:hnmobi, :kindlegen_path)
    kindlegen_arguments = " #{epub_path} -o #{Path.basename(mobi_path)}"
    shell_arguments = kindlegen_path <> kindlegen_arguments
    Logger.info "Executing shell command '#{shell_arguments}'"

    kindlegen_process = System.cmd System.get_env("SHELL"), ["-c", shell_arguments]
    kindleget_output = elem(kindlegen_process, 0)
    Logger.info "- kinglegen output start -"
    Logger.info kindleget_output
    Logger.info "- kinglegen output end -"

    if String.contains?(kindleget_output, "Error") do
        Logger.error "Kindlegen was not happy at all..."
    end

    mobi_path
  end

end