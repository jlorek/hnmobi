defmodule Hnmobi.Main.Algolia do
    use Tesla
    require Logger
    require Timex
    alias Hnmobi.Main.Article
    
    plug Tesla.Middleware.Logger
    plug Tesla.Middleware.BaseUrl, "http://hn.algolia.com/api/v1/"
    plug Tesla.Middleware.JSON

    @items 20

    # {
    #     "created_at": "2018-02-02T12:40:34.000Z",
    #     "title": "Gut Microbes Combine to Cause Colon Cancer, Study Suggests",
    #     "url": "https://www.nytimes.com/2018/02/01/health/colon-cancer-bacteria.html",
    #     "author": "montrose",
    #     "points": 210,
    #     "story_text": null,
    #     "comment_text": null,
    #     "num_comments": 47,
    #     "story_id": null,
    #     "story_title": null,
    #     "story_url": null,
    #     "parent_id": null,
    #     "created_at_i": 1517575234,
    #     "_tags": [
    #         "story",
    #         "author_montrose",
    #         "story_16290065"
    #     ],
    #     "objectID": "16290065",
    #     "_highlightResult": {
    #         "title": {
    #             "value": "Gut Microbes Combine to Cause Colon Cancer, Study Suggests",
    #             "matchLevel": "none",
    #             "matchedWords": []
    #         },
    #         "url": {
    #             "value": "https://www.nytimes.com/2018/02/01/health/colon-cancer-bacteria.html",
    #             "matchLevel": "none",
    #             "matchedWords": []
    #         },
    #         "author": {
    #             "value": "montrose",
    #             "matchLevel": "none",
    #             "matchedWords": []
    #         }
    #     }
    # },

    def top(days \\ 1) do
        yesterday = Timex.now() |> Timex.shift(days: -days) |> Timex.to_unix()
        response = get("search?tags=story&hitsPerPage=#{@items}&numericFilters=created_at_i>#{yesterday}")
        
        if response.status == 200 do
            response.body["hits"]
            |> Enum.map(&parse/1)
            |> Enum.reject(&is_nil/1)
        else
            Logger.error("Algolia API returned an error")
            []
        end
    end

    defp parse(%{"objectID" => id, "title" => title, "url" => url, "points" => score}) do
        %Article{
            hnid: id,
            title: title,
            url: url,
            score: score
        }
    end

    defp parse(_) do
        Logger.warn("Algolia search result rejected because of incomplete data")
        nil
    end
end