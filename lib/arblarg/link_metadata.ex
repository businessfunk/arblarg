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
    uri = URI.parse(url)

    cond do
      # Handle youtu.be URLs
      uri.host == "youtu.be" ->
        uri.path |> String.trim_leading("/")

      # Handle youtube.com URLs
      uri.host in ["youtube.com", "www.youtube.com"] ->
        case uri.query do
          nil -> nil
          query ->
            query
            |> URI.decode_query()
            |> Map.get("v")
        end

      true -> nil
    end
  end

  def fetch(url) do
    with {:ok, _} <- validate_url(url) do
      # Check if it's a direct image link
      if is_direct_image?(url) do
        {:ok, %{
          title: nil,
          description: nil,
          image: url,
          domain: URI.parse(url).host,
          is_youtube: false,
          youtube_id: nil
        }}
      else
        if youtube_id = extract_youtube_id(url) do
          {:ok, %{
            title: nil,
            description: nil,
            image: nil,
            domain: URI.parse(url).host,
            is_youtube: true,
            youtube_id: youtube_id
          }}
        else
          with {:ok, %{body: body}} <- HTTPoison.get(url, [], follow_redirect: true),
               {:ok, document} <- Floki.parse_document(body) do
            metadata = %{
              title: extract_title(document),
              description: extract_description(document),
              image: extract_image(document, url),
              domain: URI.parse(url).host,
              is_youtube: false,
              youtube_id: nil
            }
            {:ok, metadata}
          else
            error -> {:error, error}
          end
        end
      end
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
