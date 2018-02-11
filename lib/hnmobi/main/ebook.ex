defmodule Hnmobi.Main.Ebook do
  # useful documentation
  # https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf
  # https://pandoc.org/MANUAL.html

  require Logger

  alias Hnmobi.Main.Mercury
  alias Hnmobi.Main.HackerNews
  alias Hnmobi.Main.Algolia
  alias Hnmobi.Main.Github
  alias Hnmobi.Main.Kindlegen
  alias Hnmobi.Main.Pandoc
  alias Hnmobi.Main.Kindleunpack
  alias Hnmobi.Main.Sanitizer
  
  def generate_single(hnid) do
    article = HackerNews.details(hnid)
    generate([article])
  end

  def generate_top() do
    Algolia.top |> generate()
  end

  # def generate_multiple(articles) do
  #   generate(articles)
  # end

  def prepare_github(%{:url => url} = article) do
    github_regex = ~r/http[s]*:\/\/[www\.]*github.com\/(?<user>.+)\/(?<repo>.+)\/*/
    %{"user" => user, "repo" => repo} = Regex.named_captures(github_regex, url)
    html_path = Github.get_readme(user, repo)
    |> Pandoc.convert_from_markdown

    %{article | html_path: html_path}
  end
  
  def filter_github(hn_articles) do
    Enum.filter(hn_articles, fn %{:url => url} -> url =~ ~r/http[s]*:\/\/[www\.]*github.com/ end)
  end

  defp generate(hn_articles) do
    Logger.info "Starting ebook generation..."

    # filter github links
    Logger.info "Filtering for github links"
    github_articles = filter_github(hn_articles)
    length = length(github_articles)
    Logger.info "Found #{length} GitHub links"
    github_articles = Enum.map(github_articles, fn(gh_meta) -> prepare_github(gh_meta) end)

    # hn_articles still includes the github links?
    articles = hn_articles
    |> Enum.map(fn hn_meta -> prepare_html(hn_meta, false) end)
    |> Enum.reject(&is_nil/1)

    articles = github_articles ++ articles |> Enum.sort(&(&1.score >= &2.score))
    
    if (length(articles) == 0) do
      Logger.warn("Article list is empty, generated eBook will be very sad...")
    end

    toc_path = prepare_toc(articles)
    html_paths = Enum.map(articles, fn result -> result.html_path end)
    html_paths = [prepare_header() |[toc_path | html_paths]] ++ [prepare_footer()]
    
    {:ok, working_directory} = Temp.mkdir
    case Pandoc.convert(working_directory, html_paths) do
      {:ok, epub_path} ->
        case Kindlegen.convert(epub_path) do
          {:ok, mobi_path} -> 
            case Kindleunpack.extract_kf7(mobi_path) do
              {:ok, kf7_path} -> {:ok, kf7_path}
              _ -> {:error, ".azw (KF7) extraction failed"}
            end
          _ -> {:error, ".mobi conversion failed"}
        end
        _ -> {:error, ".epub conversion failed"}
    end
  end

  defp prepare_html(%{:hnid => id, :url => url, :title => title} = article, debug) do
    content = Mercury.get_content(url) |> Sanitizer.sanitize()

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

  defp add_debug_page(html_handle, article)do
    IO.write html_handle, "<h1 style=\"page-break-before:always\">#{article.title}</h1>"
    IO.write html_handle, "<p>Source: <a href=\"#{article.url}\">#{article.url}</a></p>"
    IO.write html_handle, "<p>ID: #{article.hnid}</p>"
    # IO.write html_handle, "<p>By: #{article.by}</p>"
    IO.write html_handle, "<p>Score: #{article.score}</p>"
    # IO.write html_handle, "<p>Time: #{article.time}</p>"
    # IO.write html_handle, "<p>Type: #{article.type}</p>"
  end

  defp prepare_header() do
      html_path = Temp.path! %{suffix: ".html"}
      Logger.info "header_path = #{html_path}"

      current_time = Timex.now
      timestamp = current_time |> Timex.to_unix
      date = current_time |> Timex.format!("{D}. {Mfull} '{YY}")
      time = current_time |> Timex.format!("{h24}:{m}:{s}")

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
    Enum.each articles, &IO.write(html_handle, "<h2># <a href=\"##{&1.hnid}\">#{&1.title}</a></h2>")
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
end