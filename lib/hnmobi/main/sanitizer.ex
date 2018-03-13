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

  defp fix_relative_img_src({name, attrs} = element, base_url) do
    case name do
      "img" -> { name, fix_relative_img_src_attribute(attrs, base_url) }
      _ -> element
    end
  end

  defp fix_relative_img_src_attribute(attrs, base_url) do
    Enum.map(attrs, fn attr ->
      attribute_name = elem(attr, 0)
      case attribute_name do
        "src" ->
          attribute_value = elem(attr, 1)
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
        Logger.info("Found one of those <iframe> tags - EVIL!")
        {"div", []}

      "embed" ->
        Logger.info("Found one of those <embed> tags - ZAP!")
        {"div", []}

      _ ->
        element
    end
  end

  defp fix_adaptive_img_src({name, attrs} = element) do
    case name do
      "img" ->
        srcset_found = Enum.any?(attrs, fn attr -> elem(attr, 0) == "srcset" end)
        data_srcset_found = Enum.any?(attrs, fn attr -> elem(attr, 0) == "data-srcset" end)
        adaptive_src_found = Enum.any?(attrs, fn attr -> elem(attr, 0) == "src" && String.contains?(elem(attr, 1), "%20http") end)
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
      attribute_name = elem(attr, 0)
      attribute_value = elem(attr, 1)
      case attribute_name do
        "src" -> {"src", String.splitter(attribute_value, "%20") |> Enum.take(1)}
        _ -> attr
      end
    end)
  end

  # these can be found here:
  # https://www.theverge.com/2018/2/5/16966530/intel-vaunt-smart-glasses-announced-ar-video
  defp fix_span_images({name, attrs} = element) do
    case name do
      "span" ->
        data_original_attribute = Enum.find(attrs, nil, fn attr -> elem(attr, 0) == "data-original" && String.starts_with?(elem(attr, 1), "http") end)
        unless (is_nil(data_original_attribute)) do
          Logger.warn("Found span image, trying to fix it.")
          img_src = elem(data_original_attribute, 1)
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
        invalid_src_attribute = Enum.find(attrs, nil, fn attr -> elem(attr, 0) == "src" && !String.starts_with?(elem(attr, 1), "http") end)
        unless (is_nil(invalid_src_attribute)) do
          img_src = elem(invalid_src_attribute, 1)
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
