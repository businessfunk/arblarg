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

# Clear existing data in the correct order to handle foreign key constraints
Repo.delete_all(Arblarg.Temporal.Shout)    # Delete shouts first
Repo.delete_all(Arblarg.Temporal.Reply)    # Delete replies
Repo.delete_all(Arblarg.Temporal.Post)     # Delete posts
Repo.delete_all(Arblarg.Communities.Community)  # Now safe to delete communities

# Define your communities
communities = [
  # General Communities
  %{
    name: "General",
    slug: "general",
    description: "General discussion about anything and everything",
    rules: "Be respectful and follow common sense guidelines",
    creator_id: "system"
  },
  %{
    name: "Random",
    slug: "random",
    description: "Random discussions and miscellaneous topics",
    rules: "Keep it civil and fun",
    creator_id: "system"
  },
  %{
    name: "News",
    slug: "news",
    description: "Current events, news, and happenings around the world",
    rules: "Post reliable sources, avoid misinformation",
    creator_id: "system"
  },
  %{
    name: "Advice",
    slug: "advice",
    description: "Seek and give advice on various life topics",
    rules: "Be constructive and supportive",
    creator_id: "system"
  },

  # Technology
  %{
    name: "Technology",
    slug: "tech",
    description: "Discuss the latest in technology, programming, and digital trends",
    rules: "Stay on topic and avoid spam",
    creator_id: "system"
  },

  # Entertainment & Media
  %{
    name: "Anime",
    slug: "anime",
    description: "Discuss anime series, movies, and culture",
    rules: "Tag spoilers, respect others' tastes",
    creator_id: "system"
  },
  %{
    name: "Manga",
    slug: "manga",
    description: "Manga discussion and recommendations",
    rules: "Tag spoilers, no pirated content links",
    creator_id: "system"
  },
  %{
    name: "Gaming",
    slug: "gaming",
    description: "Video games, gaming culture, and discussions",
    rules: "No piracy, tag spoilers",
    creator_id: "system"
  },
  %{
    name: "Pokémon",
    slug: "pokemon",
    description: "Everything Pokémon - games, cards, anime, and more",
    rules: "Keep trades in appropriate threads",
    creator_id: "system"
  },
  %{
    name: "Retro",
    slug: "retro",
    description: "Classic games, consoles, and computing",
    rules: "No ROM links or piracy discussion",
    creator_id: "system"
  },
  %{
    name: "RPG",
    slug: "rpg",
    description: "Role-playing games, both digital and tabletop",
    rules: "Be inclusive of all play styles",
    creator_id: "system"
  },
  %{
    name: "Comics",
    slug: "comics",
    description: "Comic books, graphic novels, and manga discussions",
    rules: "Tag spoilers for recent releases",
    creator_id: "system"
  },
  %{
    name: "Movies",
    slug: "movies",
    description: "Film discussion, reviews, and news",
    rules: "Tag spoilers for recent releases",
    creator_id: "system"
  },

  # Creative & Arts
  %{
    name: "Creative",
    slug: "creative",
    description: "Share and discuss creative works",
    rules: "Original content encouraged, credit others' work",
    creator_id: "system"
  },
  %{
    name: "Art",
    slug: "art",
    description: "Share and discuss artwork and illustrations",
    rules: "Credit artists, mark NSFW content",
    creator_id: "system"
  },
  %{
    name: "Cosplay",
    slug: "cosplay",
    description: "Cosplay photos, tutorials, and discussion",
    rules: "Credit cosplayers, mark NSFW content",
    creator_id: "system"
  },
  %{
    name: "Music",
    slug: "music",
    description: "Music discussion, recommendations, and news",
    rules: "No illegal download links",
    creator_id: "system"
  },
  %{
    name: "Fashion",
    slug: "fashion",
    description: "Fashion trends, advice, and discussion",
    rules: "Be constructive with criticism",
    creator_id: "system"
  },

  # Lifestyle & Hobbies
  %{
    name: "DIY",
    slug: "diy",
    description: "Do-it-yourself projects and crafts",
    rules: "Include safety warnings when necessary",
    creator_id: "system"
  },
  %{
    name: "Cooking",
    slug: "cooking",
    description: "Recipes, cooking tips, and food discussion",
    rules: "Include ingredient warnings for allergies",
    creator_id: "system"
  },
  %{
    name: "Finance",
    slug: "finance",
    description: "Financial discussion and advice",
    rules: "No pump and dump schemes",
    creator_id: "system"
  },
  %{
    name: "Travel",
    slug: "travel",
    description: "Travel tips, stories, and recommendations",
    rules: "Include content warnings for sensitive topics",
    creator_id: "system"
  },
  %{
    name: "Fitness",
    slug: "fitness",
    description: "Exercise, health, and wellness discussion",
    rules: "No dangerous diet promotion",
    creator_id: "system"
  },
  %{
    name: "Outdoors",
    slug: "outdoors",
    description: "Outdoor activities and nature appreciation",
    rules: "Follow leave-no-trace principles",
    creator_id: "system"
  },

  # Educational & Academic
  %{
    name: "Science",
    slug: "science",
    description: "Scientific discussion and news",
    rules: "Cite sources for claims",
    creator_id: "system"
  },
  %{
    name: "History",
    slug: "history",
    description: "Historical events and discussion",
    rules: "Cite sources, avoid revisionism",
    creator_id: "system"
  },

  # Special Interest
  %{
    name: "Autos",
    slug: "autos",
    description: "Automotive discussion and advice",
    rules: "No illegal modification advice",
    creator_id: "system"
  },
  %{
    name: "Nature",
    slug: "nature",
    description: "Wildlife, plants, and natural phenomena",
    rules: "Credit photographers",
    creator_id: "system"
  },
  %{
    name: "Sports",
    slug: "sports",
    description: "Sports news and discussion",
    rules: "No illegal streaming links",
    creator_id: "system"
  },
  %{
    name: "Toys",
    slug: "toys",
    description: "Toy collecting and discussion",
    rules: "Tag bootleg warnings",
    creator_id: "system"
  },
  %{
    name: "Paranormal",
    slug: "paranormal",
    description: "Discussion of paranormal phenomena",
    rules: "Respect others' beliefs",
    creator_id: "system"
  },
  %{
    name: "LGBTQ",
    slug: "lgbtq",
    description: "LGBTQ+ community discussion and support",
    rules: "Be respectful and supportive",
    creator_id: "system"
  },

  # Adult Communities (18+)
  %{
    name: "Adult",
    slug: "adult",
    description: "Adult content and discussion (18+)",
    rules: "NSFW content only, must be 18+",
    creator_id: "system"
  },
  %{
    name: "Hentai",
    slug: "hentai",
    description: "Anime and manga adult content (18+)",
    rules: "NSFW content only, must be 18+",
    creator_id: "system"
  },
  %{
    name: "Yaoi",
    slug: "yaoi",
    description: "Male/male adult content (18+)",
    rules: "NSFW content only, must be 18+",
    creator_id: "system"
  },
  %{
    name: "Yuri",
    slug: "yuri",
    description: "Female/female adult content (18+)",
    rules: "NSFW content only, must be 18+",
    creator_id: "system"
  },
  %{
    name: "Ecchi",
    slug: "ecchi",
    description: "Suggestive anime/manga content",
    rules: "No explicit content, mark NSFW",
    creator_id: "system"
  },
  %{
    name: "Cams",
    slug: "cams",
    description: "Webcam discussion (18+)",
    rules: "NSFW content only, must be 18+",
    creator_id: "system"
  },
  %{
    name: "Furry",
    slug: "furry",
    description: "Furry community and artwork",
    rules: "Mark NSFW content appropriately",
    creator_id: "system"
  }
]

# Insert all communities
Enum.each(communities, fn community ->
  case Communities.create_community(community) do
    {:ok, _} -> IO.puts("Created community: #{community.name}")
    {:error, changeset} -> IO.puts("Failed to create #{community.name}: #{inspect(changeset.errors)}")
  end
end)

IO.puts "\nSeeded #{length(communities)} communities"
