defmodule Hnmobi.EbookTest do
  use ExUnit.Case

  alias Hnmobi.Main.Ebook

  test "filter_github/1 filters github links" do
    links = [
      %{"url" => "https://github.com/jsbeckr/Darmstadtium"},
      %{"url" => "https://www.something.com"},
      %{"url" => "https://www.github.com/jsbeckr/Darmstadtium"}
    ]

    github_links = Ebook.filter_github(links)

    assert length(github_links) == 2
  end

  test "prepare_github/1 actually prepares an html file" do
    meta = Ebook.prepare_github(%{"url" => "https://github.com/jsbeckr/Darmstadtium"})

    assert String.contains?(meta.html_path, ".html")
  end
end
