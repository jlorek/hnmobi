defmodule Hnmobi.Main.Sanitizer do
  require Logger

  def sanitize(html) do
    if (is_nil(html)) do
      nil
    else
      Floki.parse(html)
      |> Floki.map(&fix_adaptive_img_src/1)
      |> Floki.map(&fix_invalid_img_src/1)
      |> Floki.map(&fix_span_images/1)
      |> Floki.map(&remove_iframe_and_embed/1)
      |> Floki.raw_html()
    end
  end

  def make_img_src_absolute(html, base_url) do
    Floki.parse(html)
    |> Floki.map(&fix_relative_img_src(&1, base_url))
    |> Floki.raw_html()
  end

  # sometimes flocki returns an array for the attribute values:
  # https://blog.ycombinator.com/intro-to-the-yc-seed-deck/
  defp get_attribute_value(attr) do
    value = elem(attr, 1)
    if (is_list(value)) do
      [first | _last] = value
      first
    else
      value
    end
  end

  defp get_attribute_name(attr) do
    elem(attr, 0)
  end

  # fix required by mozilla readability
  defp fix_relative_img_src({name, attrs} = element, base_url) do
    case name do
      "img" -> { name, fix_relative_img_src_attribute(attrs, base_url) }
      _ -> element
    end
  end

  defp fix_relative_img_src_attribute(attrs, base_url) do
    Enum.map(attrs, fn attr ->
      attribute_name = get_attribute_name(attr)
      case attribute_name do
        "src" ->
          attribute_value = get_attribute_value(attr)
          if (String.starts_with?(attribute_value, "undefined")) do
            { "src", String.replace(attribute_value, "undefined", base_url) }
          else
            attr
          end
        _ -> attr
      end
    end)
  end

  defp remove_iframe_and_embed({name, _attrs} = element) do
    case name do
      "iframe" ->
        Logger.warn("Found one of those <iframe> tags - EVIL!")
        {"div", []}

      "embed" ->
        Logger.warn("Found one of those <embed> tags - ZAP!")
        {"div", []}

      _ ->
        element
    end
  end

  defp fix_adaptive_img_src({name, attrs} = element) do
    case name do
      "img" ->
        srcset_found = Enum.any?(attrs, fn attr -> get_attribute_name(attr) == "srcset" end)
        data_srcset_found = Enum.any?(attrs, fn attr -> get_attribute_name(attr) == "data-srcset" end)
        adaptive_src_found = Enum.any?(attrs, fn attr -> get_attribute_name(attr) == "src" && String.contains?(get_attribute_value(attr), "%20http") end)
        if (srcset_found || data_srcset_found || adaptive_src_found) do
          Logger.warn("Found adaptive image, trying to fix it.")
          {name, fix_adaptive_img_src_attribute(attrs)}
        else
          element
        end
      _ ->
        element
    end
  end

  defp fix_adaptive_img_src_attribute(attrs) do
    Enum.map(attrs, fn attr ->
      attribute_name = get_attribute_name(attr)
      attribute_value = get_attribute_value(attr)
      case attribute_name do
        "src" -> {"src", String.splitter(attribute_value, "%20") |> Enum.take(1)}
        _ -> attr
      end
    end)
  end

  # a span that hold an 'data-original' attribute with the correct image src
  # these can be found here:
  # https://www.theverge.com/2018/2/5/16966530/intel-vaunt-smart-glasses-announced-ar-video
  defp fix_span_images({name, attrs} = element) do
    case name do
      "span" ->
        data_original_attribute = Enum.find(attrs, nil, fn attr -> get_attribute_name(attr) == "data-original" && String.starts_with?(get_attribute_value(attr), "http") end)
        unless (is_nil(data_original_attribute)) do
          Logger.warn("Found span image, trying to fix it.")
          img_src = get_attribute_value(data_original_attribute)
          {"img", [{"src", img_src}]}
        else
          element
        end
      _ ->
        element
    end
  end

  # these can be found here:
  # https://www.theverge.com/2018/2/5/16966530/intel-vaunt-smart-glasses-announced-ar-video
  defp fix_invalid_img_src({name, attrs} = element) do
    case name do
      "img" ->
        invalid_src_attribute = Enum.find(attrs, nil, fn attr -> get_attribute_name(attr) == "src" && !String.starts_with?(get_attribute_value(attr), "http") end)
        unless (is_nil(invalid_src_attribute)) do
          img_src = get_attribute_value(invalid_src_attribute)
          Logger.warn("Removed invalid img src attribute '#{img_src}'")
          {"div", []}
        else
          element
        end
      _ ->
        element
    end
  end
end
