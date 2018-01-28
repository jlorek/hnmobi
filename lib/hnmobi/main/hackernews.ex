defmodule Hnmobi.Main.HackerNews do
  use Tesla
  require Logger

  plug Tesla.Middleware.Logger
  plug Tesla.Middleware.BaseUrl, "https://hacker-news.firebaseio.com/v0/"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Kickass Service Worker"}
  plug Tesla.Middleware.JSON

#   {
#     "by": "pbhowmic",
#     "descendants": 128,
#     "id": 16139121,
#     "kids": [
#         16139703,
#         16139464,
#         16139705,
#         16140287,
#         16139225,
#         16140186,
#         16140246,
#         16139499,
#         16139222,
#         16139702,
#         16139818,
#         16139203,
#         16139457,
#         16140034
#     ],
#     "score": 176,
#     "time": 1515841887,
#     "title": "India has a hole where its middle class should be",
#     "type": "story",
#     "url": "https://www.economist.com/news/leaders/21734454-should-worry-both-government-and-companies-india-has-hole-where-its-middle-class-should-be"
# }

  def top do
    response = get("topstories.json")
    json = response.body

    items = json
      |> Enum.take(10)
      |> Enum.map(&details/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(&has_required_keys?/1)
      |> Enum.filter(&is_url_valid?/1)

    Logger.info "Items found: #{length(items)}"
    items
  end

  def details (id) do
    response = get("item/#{id}.json")
    case response.status do
        200 -> response.body
        _ -> nil
    end
  end

  defp has_required_keys?(%{"id" => _, "url" => _, "title" => _}), do: true

  defp has_required_keys?(_), do: false

  defp is_url_valid?(%{"url" => url}) do
    ok = cond do
      String.contains?(url, "twitter.com") -> false
      String.contains?(url, "github.com") -> false
      String.contains?(url, "youtube.com") -> false
      String.ends_with?(url, ".pdf") -> false
      true -> true
    end

    unless ok do Logger.info "Article '#{url}' was rejected by URL filter" end
    ok
  end
end