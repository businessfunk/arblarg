if Mix.env() in [:dev, :test] do
  if File.exists?(".env") do
    File.stream!(".env")
    |> Stream.map(&String.trim/1)
    |> Enum.each(fn line ->
      if !String.starts_with?(line, "#") && String.contains?(line, "=") do
        [key, value] = String.split(line, "=", parts: 2)
        System.put_env(String.trim(key), String.trim(value))
      end
    end)
  end
end
