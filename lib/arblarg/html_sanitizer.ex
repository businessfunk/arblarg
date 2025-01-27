defmodule Arblarg.HtmlSanitizer do
  import Phoenix.HTML, only: [raw: 1]
  import HtmlEntities

  @doc """
  Sanitizes user input to prevent XSS attacks while allowing only links
  """
  def sanitize(nil), do: nil
  def sanitize(text) when is_binary(text) do
    text
    |> HtmlEntities.encode()  # First encode all HTML entities
    |> linkify()              # Then convert URLs to links
    |> raw()                  # Finally mark as safe HTML
  end

  # Convert URLs to clickable links
  defp linkify(text) do
    url_regex = ~r/https?:\/\/[^\s<>]+/

    Regex.replace(url_regex, text, fn url ->
      case validate_url(url) do
        {:ok, valid_url} ->
          # Only allow specific HTML attributes for links
          "<a href=\"#{HtmlEntities.encode(valid_url)}\" " <>
            "class=\"text-red-400 hover:text-red-300 hover:underline\" " <>
            "rel=\"nofollow noopener\" " <>
            "target=\"_blank\">" <>
            "#{HtmlEntities.encode(format_url_for_display(url))}</a>"
        _ ->
          HtmlEntities.encode(url)
      end
    end)
  end

  # Validate URL to prevent javascript: and other malicious protocols
  defp validate_url(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host}
      when scheme in ["http", "https"] and is_binary(host) ->
        {:ok, url}
      _ ->
        :error
    end
  end

  # Format URL for display by removing protocol and truncating if too long
  defp format_url_for_display(url) do
    url
    |> String.replace(~r{^https?://}, "")
    |> String.replace(~r{/$}, "")
    |> truncate_url()
  end

  defp truncate_url(url) when byte_size(url) > 50 do
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
