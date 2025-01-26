# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Arblarg.Repo.insert!(%Arblarg.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Start the application to ensure all dependencies are available
Application.ensure_all_started(:arblarg)

alias Arblarg.Communities
alias Arblarg.Repo

# Clear existing communities
Repo.delete_all(Arblarg.Communities.Community)

# Define your communities
communities = [
  %{
    name: "General",
    slug: "general",
    description: "General discussion about anything and everything",
    rules: "Be respectful and follow common sense guidelines",
    creator_id: "system"
  },
  %{
    name: "Technology",
    slug: "tech",
    description: "Discuss the latest in technology, programming, and digital trends",
    rules: "Stay on topic and avoid spam",
    creator_id: "system"
  },
  %{
    name: "Creative",
    slug: "creative",
    description: "Share and discuss art, music, writing, and other creative works",
    rules: "Original content encouraged, credit others' work",
    creator_id: "system"
  }
  # Add more communities as needed
]

# Insert all communities
Enum.each(communities, fn community ->
  case Communities.create_community(community) do
    {:ok, _} -> IO.puts("Created community: #{community.name}")
    {:error, changeset} -> IO.puts("Failed to create #{community.name}: #{inspect(changeset.errors)}")
  end
end)

IO.puts "\nSeeded #{length(communities)} communities"
