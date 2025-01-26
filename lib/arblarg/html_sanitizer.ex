defmodule Arblarg.HtmlSanitizer do
  import Phoenix.HTML, only: [raw: 1]
  import HtmlEntities

  @doc """
  Sanitizes user input to prevent XSS attacks while allowing basic formatting
  """
  def sanitize(nil), do: nil
  def sanitize(text) when is_binary(text) do
    text
    |> HtmlEntities.encode()  # First encode the text to prevent XSS
    |> linkify()              # Then convert URLs to links
    |> raw()                  # Finally mark as safe HTML
  end

  # Convert URLs to clickable links
  defp linkify(text) do
    url_regex = ~r/https?:\/\/[^\s<>]+/

    Regex.replace(url_regex, text, fn url ->
      case Arblarg.LinkMetadata.validate_url(url) do
        {:ok, valid_url} ->
          # Encode URLs in href to prevent XSS
          "<a href=\"#{HtmlEntities.encode(valid_url)}\" rel=\"nofollow noopener\" target=\"_blank\">#{url}</a>"
        _ ->
          url
      end
    end)
  end

  # Format URL for display by removing protocol and truncating if too long
  defp format_url_for_display(url) do
    url
    |> String.replace(~r{^https?://}, "")
    |> String.replace(~r{/$}, "")
    |> truncate_url()
  end

  defp truncate_url(url) when byte_size(url) > 50 do
    # Split URL into parts
    case URI.parse(url) do
      %URI{host: host, path: path} when is_binary(host) and is_binary(path) ->
        path_parts = String.split(path, "/", trim: true)
        case path_parts do
          [] -> host
          [first | rest] when length(rest) > 0 ->
            "#{host}/#{first}/..."
          [single] ->
            "#{host}/#{single}"
        end
      _ ->
        String.slice(url, 0, 47) <> "..."
    end
  end
  defp truncate_url(url), do: url
end
