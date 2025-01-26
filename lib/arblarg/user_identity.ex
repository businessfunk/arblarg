defmodule Arblarg.UserIdentity do
  @salt "user-identity-v1"

  def generate_tripcode(user_id, content_salt \\ "", existing_names \\ [], opts \\ []) do
    base_name = generate_base_name(user_id, content_salt)
    is_op = Keyword.get(opts, :is_op, false)

    name = if base_name in existing_names do
      # If name exists, try numbers until we find a unique one
      Stream.iterate(2, & &1 + 1)
      |> Enum.reduce_while(base_name, fn num, name ->
        numbered_name = "#{name}#{num}"
        if numbered_name in existing_names do
          {:cont, name}
        else
          {:halt, numbered_name}
        end
      end)
    else
      base_name
    end

    # Return a tuple with the name and OP status
    {name, is_op}
  end

  defp generate_base_name(user_id, content_salt) do
    # Combine user_id with content_salt to create unique combinations
    combined = user_id <> content_salt <> @salt

    :crypto.hash(:sha256, combined)
    |> Base.encode16(case: :lower)
    |> String.slice(0, 6)
    |> tripcode_to_name()
  end

  # Converts a hex string into a more readable format like "RedPanda123"
  defp tripcode_to_name(hex) do
    # Split the hex into parts for adjective and animal
    <<adj::binary-size(2), animal::binary-size(4)>> = String.slice(hex, 0, 6)

    # Convert parts to indices
    adj_index = String.to_integer(adj, 16) |> rem(length(adjectives()))
    animal_index = String.to_integer(animal, 16) |> rem(length(animals()))

    # Combine parts
    Enum.at(adjectives(), adj_index) <>
    Enum.at(animals(), animal_index)
  end

  defp adjectives do
    ~w(Sleepy Fluffy Cozy Snuggly Fuzzy Bouncy Happy Silly Cuddly Tiny Playful Gentle Sweet Merry)
  end

  defp animals do
    ~w(Kitten Puppy Bunny Hamster Ferret Panda Fox Kitty Corgi Shiba Otter Chinchilla Squirrel Raccoon)
  end
end
