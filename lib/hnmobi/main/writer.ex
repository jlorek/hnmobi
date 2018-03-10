defmodule Hnmobi.Main.Writer do
  require Logger

  alias Hnmobi.Main.Pandoc
  alias Hnmobi.Main.Sanitizer

  def create_html(article) do
    case from(article.content_format, article, false) do
      {:ok, html_path} -> %{article | html_path: html_path}
      _ -> article
    end
  end

  defp from(:html, %{:hnid => id, :title => title, :content => content} = article, debug) do
    case Temp.path %{suffix: ".html"} do
      {:ok, html_path } ->
        Logger.info "html_path = #{html_path}"
        case File.open html_path, [:write, :utf8] do
          {:ok, handle} ->
            if debug, do: write_html_debug(article, handle)
            # https://www.w3schools.com/cssref/pr_print_pagebb.asp
            IO.write handle, "<a name=\"#{id}\"></a>"
            IO.write handle, "<h1 style=\"page-break-before:always\">#{title}</h1>"
            IO.write handle, Sanitizer.sanitize(content)
            File.close handle
            {:ok, html_path}
          _ ->
            Logger.error "Could not open html article file"
            {:error}
        end
      _ ->
        Logger.error "Could not generate html article path"
        {:error}
    end
  end

  defp write_html_debug(article, handle) do
    IO.write handle, "<h1 style=\"page-break-before:always\">#{article.title}</h1>"
    IO.write handle, "<p>Source: <a href=\"#{article.url}\">#{article.url}</a></p>"
    IO.write handle, "<p>ID: #{article.hnid}</p>"
    # IO.write handle, "<p>By: #{article.by}</p>"
    IO.write handle, "<p>Score: #{article.score}</p>"
    # IO.write handle, "<p>Time: #{article.time}</p>"
    # IO.write handle, "<p>Type: #{article.type}</p>"
  end

  defp from(:md, %{:hnid => id, :title => title, :content => content} = article, debug) do
    case Temp.path %{suffix: ".md"} do
      {:ok, md_path } ->
        Logger.info "md_path = #{md_path}"
        case File.open(md_path, [:write, :utf8]) do
          {:ok, handle} ->
            if debug, do: write_md_debug(article, handle)
            #IO.write handle, "## <a name=\"#{id}\"></a>#{title}\n"
            IO.write handle, content
            File.close handle
            html_path = Pandoc.convert_from_markdown(md_path)
            {:ok, html_path}
          _ ->
            Logger.error "Could not open html article file"
            {:error}
        end
      _ ->
        Logger.error "Could not generate html article path"
        {:error}
    end
  end

  defp write_md_debug(_article, _handle) do
    # todo - write some debug md
    # IO.write handle, "<h1 style=\"page-break-before:always\">#{article.title}</h1>"
    # IO.write handle, "<p>Source: <a href=\"#{article.url}\">#{article.url}</a></p>"
    # IO.write handle, "<p>ID: #{article.hnid}</p>"
    # IO.write handle, "<p>By: #{article.by}</p>"
    # IO.write handle, "<p>Score: #{article.score}</p>"
    # IO.write handle, "<p>Time: #{article.time}</p>"
    # IO.write handle, "<p>Type: #{article.type}</p>"
  end

  defp from(_format, article, _debug) do
    Logger.warn("Cannot create HTML for the given article, HNID = '#{article.hnid}'")
    article
  end
end