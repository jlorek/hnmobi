defmodule Hnmobi.Main.Mercury do
  use Tesla
  require Logger

  plug Tesla.Middleware.Logger
  plug Tesla.Middleware.BaseUrl, "https://mercury.postlight.com/"
  plug Tesla.Middleware.Headers, %{"x-api-key" => "a2VPIAB3CvJVAjkUWde2wNVI5rbMlG9Oktm2gfv9"}
  plug Tesla.Middleware.JSON

  #curl -H "x-api-key: a2VPIAB3CvJVAjkUWde2wNVI5rbMlG9Oktm2gfv9" "https://mercury.postlight.com/parser?url=https://trackchanges.postlight.com/building-awesome-cms-f034344d8ed"
  # HTTP/1.0 200 OK
  # {
  #   "title": "An Ode to the Rosetta Spacecraft as It Flings Itself Into a Comet",
  #   "content": "<div><article class="content body-copy"> <p>Today, the European Space Agency’s... ",
  #   "date_published": "2016-09-30T07:00:12.000Z",
  #   "lead_image_url": "https://www.wired.com/wp-content/uploads/2016/09/Rosetta_impact-1-1200x630.jpg",
  #   "dek": "Time to break out the tissues, space fans.",
  #   "url": "https://www.wired.com/2016/09/ode-rosetta-spacecraft-going-die-comet/",
  #   "domain": "www.wired.com",
  #   "excerpt": "Time to break out the tissues, space fans.",
  #   "word_count": 1031,
  #   "direction": "ltr",
  #   "total_pages": 1,
  #   "rendered_pages": 1,  
  #   "next_page_url": null
  # }

  def sanatize() do
    html = get_content("https://torrentfreak.com/cloudflare-terminates-service-to-sci-hub-domain-names-180205/")
    sanatize(html)
  end

  def sanatize(html) do
    Floki.parse(html) |> Floki.map(fn({name, attrs}) ->
      attrs = case name do
        "img" ->
          srcset_found = Enum.any?(attrs, fn (attr) -> elem(attr, 0) == "srcset" end)
          if (srcset_found) do
            Logger.warn "Found one of there srcset fancy bitches!"
            Enum.map(attrs, fn(attr) ->
              attribute_name = elem(attr, 0)
              case attribute_name do
                "src" -> {"src", String.splitter(elem(attr, 1), "%20") |> Enum.take(1) }
                _ -> attr
              end
            end)
          else
            attrs
          end
        _ -> attrs
        end
      {name, attrs}
    end) |> Floki.raw_html()
  end

  def get_content (url) do
    Logger.info "Mercury is processing url '#{url}'"
    response = get("parser?url=#{url}")
    if response.status == 200 do
      json = response.body
      extract_content(json)
    else
      Logger.warn "Could not fetch '#{url}' with Mercury"
      nil
    end
  end

  defp extract_content(article) do
    cond do
      is_content_empty?(article) -> nil
      has_too_few_words?(article) -> nil
      true -> sanatize(article["content"])
    end
  end

  defp is_content_empty?(%{"content" => content}) do
    case content do
      nil -> true
      "" -> true
      "<div></div>" -> true # returned by http://maps.arcgis.com/apps/StorytellingSwipe/index.html?appid=e5160a8d1d3649f09a756c317bd0b56b
      _ -> false
    end
  end

  defp is_content_empty?(_), do: true

  defp has_too_few_words?(%{"word_count" => word_count}) do
    word_count < 50
  end
end
