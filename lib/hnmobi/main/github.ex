defmodule Hnmobi.Main.Github do
  # example
  # http://localhost:4000/mobi/16352611
  use Tesla
  require Logger

  plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.BaseUrl, "https://api.github.com")
  plug(Tesla.Middleware.Headers, %{"User-Agent" => "Kickass Service Worker"})
  plug(Tesla.Middleware.JSON)

  def get_content(url) when is_binary(url) do
    github_regex = ~r/http[s]*:\/\/[www\.]*github.com\/(?<user>.+)\/(?<repo>.+)\/*/
    %{"user" => user, "repo" => repo} = Regex.named_captures(github_regex, url)
    Logger.info("Get Readme.md for user: #{user} and repo: #{repo}")

    # todo - some status 200 checks
    %{"download_url" => download_url} = get("/repos/#{user}/#{repo}/readme").body
    content = Tesla.get(download_url).body
    content
  end

  def get_content(%{:url => url} = article) do
    content = get_content(url)
    unless (is_nil(content)) do
      %{article | content: content, content_format: :md}
    else
      article
    end
  end

end
