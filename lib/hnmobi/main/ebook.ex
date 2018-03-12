defmodule Hnmobi.Main.Ebook do
  # useful documentation
  # https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf
  # https://pandoc.org/MANUAL.html

  require Logger

  alias Hnmobi.Main.HackerNews
  alias Hnmobi.Main.Algolia
  alias Hnmobi.Main.Kindlegen
  alias Hnmobi.Main.Pandoc
  alias Hnmobi.Main.Kindleunpack
  alias Hnmobi.Main.Scraper
  alias Hnmobi.Main.Writer
  
  def generate_single(hnid) do
    article = HackerNews.details(hnid)
    unless is_nil(article) do
      generate([article])
    else
      Logger.error("Cannot generate eBook for invalid HNID")
    end
  end

  def generate_top() do
    Algolia.top() |> generate()
  end

  defp generate(hn_articles) do
    Logger.info "Starting ebook generation..."

    articles = hn_articles
      |> Enum.map(&Scraper.scrape/1)
      |> Enum.reject(fn article -> article.content_format == :none end)
      |> Enum.map(&Writer.create_html/1)
      |> Enum.filter(&File.exists?(&1.html_path))
      |> Enum.take(8)

    toc_path = prepare_toc(articles)
    html_paths = Enum.map(articles, fn article -> article.html_path end)
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

  defp prepare_header() do
      html_path = Temp.path! %{suffix: ".html"}
      Logger.info "header_path = #{html_path}"

      current_time = Timex.now
      #timestamp = current_time |> Timex.to_unix
      #time = current_time |> Timex.format!("{h24}:{m}:{s}")
      date = current_time |> Timex.format!("{D}. {Mfull} '{YY}")

      case File.open html_path, [:write, :utf8] do
        {:ok, html_handle} ->
          IO.write html_handle, "<html><head><title>hackernews.mobi - #{date}</title></head><body>"
          #IO.write html_handle, "<h1>hackernews.mobi</h1>"
          #IO.write html_handle, "<img src=\"https://t2.rbxcdn.com/fe91a04c36cb2552ea36e4cf36598264\" />"
          IO.write html_handle, "<h1>Issue #{date}</h1>"
          logo_path = "#{HnmobiWeb.Endpoint.url}/images/ebook_logo.jpg"
          IO.write html_handle, "<img src=\"#{logo_path}\" />"
          IO.write html_handle, "<div>Welcome to hackernews.mobi</div>"
          IO.write html_handle, "<div>Enjoy your read</div>"
          #IO.write html_handle, "<div>Issue #{date}</div>"
          #IO.write html_handle, "<p>Generated at #{time} (UTC)</p>"
          File.close html_handle
          html_path
        _ ->
          Logger.error("Could not generate header html file")
          nil
      end
  end

  defp prepare_toc(articles) do
    html_path = Temp.path! %{suffix: ".html"}
    Logger.info "toc_path = #{html_path}"
    
    {:ok, html_handle} = File.open html_path, [:write, :utf8]
    IO.write html_handle, "<h1 style=\"page-break-before:always\">Articles</h1>"
    IO.write html_handle, "<ul>"
    Enum.each(articles, fn article ->
      IO.write(html_handle, "<li><a href=\"##{article.hnid}\">#{article.title}</a> (#{article.reading_time_min} min)</li>")
    end)
    IO.write html_handle, "</ul>"
    File.close html_handle
    html_path
  end

  defp prepare_footer() do
    html_path = Temp.path! %{suffix: ".html"}
    Logger.info "footer_path = #{html_path}"
    {:ok, html_handle} = File.open html_path, [:write, :utf8]
    IO.write html_handle, "<h1 style=\"page-break-before:always\">Till next time</h1>"
    IO.write html_handle, "<div>To update your delivery settings visit <a href=\"http://www.hackernews.mobi\">hackernews.mobi</a></div>"
    IO.write html_handle, "</body></html>"
    File.close html_handle
    html_path
  end
end