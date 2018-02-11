defmodule Hnmobi.Main.HackerNews do
  use Tesla
  require Logger
  alias Hnmobi.Main.Article

  plug Tesla.Middleware.Logger
  plug Tesla.Middleware.BaseUrl, "https://hacker-news.firebaseio.com/v0/"
  plug Tesla.Middleware.Headers, %{"User-Agent" => "Kickass Service Worker"}
  plug Tesla.Middleware.JSON

  @items 10

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

  def top() do
    response = get("topstories.json")
    expand_hnids(response.body)
  end

  def best() do
    response = get("beststories.json")
    expand_hnids(response.body)
  end

  defp expand_hnids(hnids) do
    items = hnids
    |> Enum.take(@items)
    |> Enum.map(&details/1)
    |> Enum.reject(&is_nil/1)

    Logger.info "Items found: #{length(items)}"
    items
  end

  def details (id) do
    response = get("item/#{id}.json")
    case response.status do
        200 -> parse(response.body)
        _ -> nil
    end
  end

  defp parse(%{"id" => id, "title" => title, "url" => url, "score" => score, "type" => type}) do
    %Article{
        hnid: id,
        title: title,
        url: url,
        score: score,
        type: type
    }
  end

  defp parse(_) do
    Logger.warn "Hackernews item was rejected because of incomplete data"
    nil
  end
end