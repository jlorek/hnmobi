defmodule Hnmobi.Main.Scraper do
  require Logger

  alias Hnmobi.Main.Mercury
  alias Hnmobi.Main.Github
  alias Hnmobi.Main.Mozilla

  # https://blog.medium.com/read-time-and-you-bc2048ab620c
  @words_per_minute 275  

  def scrape(%{:url => _url} = article) do

    Logger.info("Starting to scrape HNID '#{article.hnid}'")
    Logger.info("Title = '#{article.title}'")
    Logger.info("Url = '#{article.url}'")

    engine = decide_engine(article)
    Logger.info("Engine = '#{engine}'")

    article = case engine do
      :github -> Github.get_content(article)
      :mercury -> Mercury.get_content(article)
      :mozilla -> Mozilla.get_content(article)
      _ -> article
    end

    unless (engine == :none) do
      article |> remove_short_and_long_content() |> calculate_reading_time()
    else
      article
    end
  end

  defp decide_engine(%{:url => url, :title => title}) do
    cond do
      skip_url?(url) -> :none
      skip_title?(title) -> :none
      String.match?(url, ~r/https*:\/\/(www\.)*github.com/) -> :github
      String.match?(url, ~r/https*:\/\/android-developers.googleblog.com/) -> :mercury
      #true -> :mercury
      true -> :mozilla
    end
  end

  defp skip_url?(url) do
    skip = cond do
      is_nil(url) -> true
      url == "" -> true
      String.contains?(url, "github.com") -> true
      String.contains?(url, "gist.github.com") -> true
      String.contains?(url, "twitter.com") -> true
      String.contains?(url, "youtube.com") -> true
      String.contains?(url, "independent.co.uk") -> true
      String.ends_with?(url, ".pdf") -> true
      true -> false
    end

    if skip do Logger.info "Article '#{url}' was rejected by URL filter" end
    skip
  end

  defp skip_title?(title) do
    skip = cond do
      is_nil(title) -> true
      title == "" -> true
      String.contains?(title, "Ask HN") -> true
      String.contains?(title, "Show HN") -> true
      true -> false
    end

    if skip do Logger.info "Article '#{title}' was rejected by title filter" end
    skip
  end

  defp remove_short_and_long_content(article) do
    words = String.splitter(article.content, " ") |> Enum.count()
    too_short = (words < @words_per_minute)
    too_long = (words > @words_per_minute * 19)

    if (too_short) do
      Logger.info("Article '#{article.title}' was rejected because #{words} words is too short.")
    end

    # useful for articles like this, that yield in a 29min to read whole blog scrape
    # http://jordi.inversethought.com/blog/advent-of-d/#day18
    if (too_long) do
      Logger.info("Article '#{article.title}' was rejected because #{words} words is too long.")      
    end

    case (too_short || too_long) do
      # reset the content format to avoid further processing
      true -> %{article | content: "", content_format: :none}
      false -> article
    end
  end

  defp calculate_reading_time(article) do
    words = String.splitter(article.content, " ") |> Enum.count()
    time = round(words / @words_per_minute)
    %{article | reading_time_min: time }
  end

end