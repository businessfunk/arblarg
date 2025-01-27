defmodule Arblarg.LinkMetadata do
  @moduledoc """
  Fetches and extracts metadata from URLs.
  """

  @image_extensions ~w(.jpg .jpeg .png .gif .webp)

  @allowed_schemes ["http", "https"]
  @blocked_domains ["localhost", "127.0.0.1", "0.0.0.0", "[::1]"]
  @blocked_tlds [".local", ".internal", ".test", ".example", ".invalid"]

  @youtube_domains ["youtube.com", "youtu.be", "www.youtube.com"]

  def validate_url(url) when is_binary(url) do
    uri = URI.parse(url)

    cond do
      uri.scheme not in @allowed_schemes ->
        {:error, "Invalid URL scheme"}

      is_nil(uri.host) ->
        {:error, "Invalid URL host"}

      String.contains?(uri.host, @blocked_domains) ->
        {:error, "Invalid URL domain"}

      Enum.any?(@blocked_tlds, &String.ends_with?(uri.host, &1)) ->
        {:error, "Invalid URL TLD"}

      true ->
        {:ok, url}
    end
  end

  def validate_url(_), do: {:error, "Invalid URL format"}

  def is_youtube_url?(url) do
    uri = URI.parse(url)
    uri.host in @youtube_domains
  end

  def extract_youtube_id(url) do
    cond do
      String.contains?(url, "youtube.com/watch") ->
        case URI.parse(url) do
          %URI{query: query} when is_binary(query) ->
            case URI.decode_query(query) do
              %{"v" => id} when is_binary(id) -> {:ok, id}
              _ -> {:error, "No video ID found"}
            end
          _ -> {:error, "Invalid YouTube URL"}
        end
      String.contains?(url, "youtu.be/") ->
        case Regex.run(~r{youtu\.be/([^?]+)}, url) do
          [_, id] -> {:ok, id}
          _ -> {:error, "Invalid YouTube URL"}
        end
      true -> {:error, "Not a YouTube URL"}
    end
  end

  def fetch(url) do
    case extract_youtube_id(url) do
      {:ok, _} ->
        fetch_youtube_metadata(url)
      _ ->
        # Existing general metadata fetching logic
        case HTTPoison.get(url, [], follow_redirect: true, max_redirects: 5) do
          {:ok, %{status_code: 200, body: body}} ->
            case Floki.parse_document(body) do
              {:ok, document} ->
                {:ok, %{
                  title: extract_title(document),
                  description: extract_description(document),
                  image: extract_image(document, url),
                  domain: extract_domain(url),
                  is_youtube: false,
                  youtube_id: nil
                }}
              _ -> {:error, "Failed to parse HTML"}
            end
          _ -> {:error, "Failed to fetch URL"}
        end
    end
  end

  defp fetch_youtube_metadata(url) do
    case extract_youtube_id(url) do
      {:ok, youtube_id} ->
        # Fetch video metadata using YouTube oEmbed API
        case HTTPoison.get("https://www.youtube.com/oembed?url=#{url}&format=json") do
          {:ok, %{status_code: 200, body: body}} ->
            case Jason.decode(body) do
              {:ok, data} ->
                {:ok, %{
                  title: data["title"],
                  description: nil, # YouTube oEmbed doesn't provide description
                  image: "https://img.youtube.com/vi/#{youtube_id}/maxresdefault.jpg",
                  domain: "www.youtube.com",
                  is_youtube: true,
                  youtube_id: youtube_id
                }}
              _ -> {:error, "Failed to parse YouTube metadata"}
            end
          _ -> {:error, "Failed to fetch YouTube metadata"}
        end
      _ -> {:error, "Not a YouTube URL"}
    end
  end

  defp extract_title(document) do
    document
    |> Floki.find("meta[property='og:title']")
    |> extract_content()
    |> case do
      nil ->
        document
        |> Floki.find("title")
        |> Floki.text()
        |> case do
          "" -> nil
          title -> String.trim(title)
        end
      title -> title
    end
    |> maybe_store_youtube_title()
  end

  defp maybe_store_youtube_title(nil), do: nil
  defp maybe_store_youtube_title(title) do
    case Regex.run(~r/^(.*?)\s*-\s*YouTube$/, title) do
      [_, video_title] -> String.trim(video_title)
      _ -> title
    end
  end

  defp extract_description(document) do
    document
    |> Floki.find("meta[property='og:description']")
    |> extract_content()
    |> case do
      nil ->
        document
        |> Floki.find("meta[name='description']")
        |> extract_content()
      desc -> desc
    end
  end

  defp extract_image(document, url) do
    document
    |> Floki.find("meta[property='og:image']")
    |> extract_content()
    |> maybe_absolute_url(url)
  end

  defp extract_content([]), do: nil
  defp extract_content([element | _]) do
    case Floki.attribute(element, "content") do
      [content | _] -> String.trim(content)
      _ -> nil
    end
  end

  defp extract_domain(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> host
      _ -> nil
    end
  end

  defp maybe_absolute_url(nil, _base_url), do: nil
  defp maybe_absolute_url(url, base_url) do
    case URI.parse(url) do
      %URI{scheme: nil} -> URI.merge(base_url, url) |> to_string()
      _ -> url
    end
  end

  defp is_direct_image?(url) do
    extension = url |> String.downcase() |> Path.extname()
    extension in @image_extensions
  end
end
