defmodule Arblarg.TemporalTest do
  use Arblarg.DataCase
  alias Arblarg.Temporal
  alias Arblarg.Temporal.Post

  describe "posts" do
    @valid_attrs %{
      "body" => "some body",
      "author" => "some author",
      "expires_at" => DateTime.add(DateTime.utc_now(), 86400)
    }
    @valid_link_attrs %{
      "link" => "https://example.com",
      "expires_at" => DateTime.add(DateTime.utc_now(), 86400)
    }
    @invalid_attrs %{"body" => nil, "author" => nil, "expires_at" => nil}

    test "list_active_posts/0 returns only unexpired posts" do
      expired_post = create_post(%{"expires_at" => DateTime.add(DateTime.utc_now(), -1)})
      active_post = create_post()

      posts = Temporal.list_active_posts()

      assert length(posts) == 1
      assert hd(posts).id == active_post.id
      refute Enum.any?(posts, fn p -> p.id == expired_post.id end)
    end

    test "create_post/1 with valid data creates a post" do
      assert {:ok, %Post{} = post} = Temporal.create_post(@valid_attrs)
      assert post.body == "some body"
      assert post.author == "some author"
    end

    test "create_post/1 with valid link creates a post" do
      assert {:ok, %Post{} = post} = Temporal.create_post(@valid_link_attrs)
      assert post.link == "https://example.com"
      assert post.author == "Anonymous"
    end

    test "create_post/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Temporal.create_post(@invalid_attrs)
    end

    test "create_post/1 requires either body or link" do
      attrs = %{"expires_at" => DateTime.add(DateTime.utc_now(), 86400)}
      assert {:error, changeset} = Temporal.create_post(attrs)
      assert "either body or link is required" in errors_on(changeset).body
    end

    test "create_post/1 validates link format" do
      attrs = Map.put(@valid_attrs, "link", "not-a-url")
      assert {:error, changeset} = Temporal.create_post(attrs)
      assert "must be a valid URL" in errors_on(changeset).link
    end

    test "create_reply/2 with valid data creates a reply" do
      post = create_post()
      reply_attrs = %{"body" => "some reply", "author" => "replier"}

      assert {:ok, reply} = Temporal.create_reply(post.id, reply_attrs)
      assert reply.body == "some reply"
      assert reply.author == "replier"
      assert reply.post_id == post.id
    end

    test "create_reply/2 with invalid data returns error changeset" do
      post = create_post()
      assert {:error, %Ecto.Changeset{}} = Temporal.create_reply(post.id, %{"body" => nil})
    end
  end

  # Helper function to create a test post
  defp create_post(attrs \\ %{}) do
    default_attrs = %{
      "body" => "test post",
      "author" => "test author",
      "expires_at" => DateTime.add(DateTime.utc_now(), 86400)
    }

    {:ok, post} =
      default_attrs
      |> Map.merge(Enum.into(attrs, %{}))
      |> Temporal.create_post()

    post
  end
end
