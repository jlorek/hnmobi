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

  def get_content(url) when is_binary(url) do
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

  def get_content(%{:url => url} = article) do
    content = get_content(url)
    unless (is_nil(content)) do
      %{article | content: content, content_format: :html}
    else
      article
    end
  end

  defp extract_content(article) do
    cond do
      has_too_few_words?(article) -> nil
      true -> article["content"]
    end
  end

  # todo - move these checks into the scraper  
  defp has_too_few_words?(%{"word_count" => word_count}) do
    word_count < 150
  end
end
