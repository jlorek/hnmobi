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

    articles = Enum.map(hn_articles, &Scraper.scrape/1)
      |> Enum.reject(fn article -> article.content_format == :none end)
      |> Enum.map(&Writer.create_html/1)
      |> Enum.filter(&File.exists?(&1.html_path))

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