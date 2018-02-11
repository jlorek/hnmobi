defmodule Hnmobi.Main.Github do
  use Tesla
  require Logger

  plug(Tesla.Middleware.Logger)
  plug(Tesla.Middleware.BaseUrl, "https://api.github.com")
  plug(Tesla.Middleware.Headers, %{"User-Agent" => "Kickass Service Worker"})
  plug(Tesla.Middleware.JSON)

  def get_readme(user, repo) do
    Logger.info("Get Readme.md for user: #{user} and repo: #{repo}")
    %{"download_url" => download_url} = get("/repos/#{user}/#{repo}/readme").body
    readme_content = Tesla.get(download_url).body

    case Temp.path(%{suffix: ".md"}) do
      {:ok, md_path} ->
        Logger.info("md_path = #{md_path}")

        case File.open(md_path, [:write, :utf8]) do
          {:ok, md_handle} ->
            IO.write(md_handle, readme_content)
            File.close(md_handle)

          _ ->
            Logger.error("Could not open html article file")
            nil
        end

        md_path
      _ ->
        Logger.error("Could not generate readme.md path")
        nil
    end
  end

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
