defmodule Hnmobi.Main.Scraper do
  require Logger

  alias Hnmobi.Main.Mercury
  alias Hnmobi.Main.Github
  alias Hnmobi.Main.Mozilla

  def scrape(%{:url => _url} = article) do
    engine = decide_engine(article)
    Logger.info("Using '#{engine}' for '#{article.url}'")

    article = case engine do
      :github -> Github.get_content(article)
      :mercury -> Mercury.get_content(article)
      :mozilla -> Mozilla.get_content(article)
      _ -> article
    end

    remove_empty_content(article)
  end

  defp decide_engine(%{:url => url}) do
    cond do
      skip_url?(url) -> :none
      String.match?(url, ~r/http[s]*:\/\/[www\.]*github.com/) -> :github
      #true -> :mercury
      true -> :mozilla
    end
  end

  defp skip_url?(url) do
    skip = cond do
      is_nil(url) -> true
      url == "" -> true
      String.contains?(url, "gist.github.com") -> true
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
      # reset the content format to avoid further processing
      true -> %{article | content: "", content_format: :none}
      false -> article
    end
  end

end