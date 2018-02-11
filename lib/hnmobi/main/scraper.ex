defmodule Hnmobi.Main.Scraper do
  require Logger

  alias Hnmobi.Main.Mercury
  alias Hnmobi.Main.Github

  def scrape(%{:url => _url} = article) do
    engine = decide_engine(article)
    Logger.info("Using '#{engine}' for '#{article.url}'")

    article = case engine do
      :github -> Github.get_content(article)
      :mercury -> Mercury.get_content(article) 
      _ -> article
    end

    remove_empty_content(article)
  end

  defp decide_engine(%{:url => url} = article) do
    cond do
      is_nil(url) -> :none
      skip_url?(article) -> :none
      String.match?(url, ~r/http[s]*:\/\/[www\.]*github.com/) -> :github
      true -> :mercury
    end
  end

  defp skip_url?(%{:url => url}) do
    skip = cond do
      String.contains?(url, "twitter.com") -> true
      String.contains?(url, "youtube.com") -> true
      String.ends_with?(url, ".pdf") -> true
      true -> false
    end

    if skip do Logger.info "Article '#{url}' was rejected by URL filter" end
    skip
  end

  defp remove_empty_content(%{:content => content} = article) do
    empty = case content do
      nil -> true
      "" -> true
      "<body></body>" -> true
      "<div></div>" -> true
      _ -> false
    end

    case empty do
      true -> %{article | content: "", content_format: :none}
      false -> article
    end
  end

end