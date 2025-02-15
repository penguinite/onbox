import quark/[users, posts, debug, db]
import std/[unittest], rng

# Let's get started!
var dbcon = connectToDb()

echo "Dropping everything already in db"
dbcon.cleanDb()
echo"Setting up db again"
dbcon.setup()

# Add the fake users.
for user in genFakeUsers():
  dbcon.addUser(user)

# A post that we have full control over.
var post = newPost(
  sender = "scout",
  content = @[text(sample(fakeStatuses))]
)


suite "Post-related tests":
  test "Add custom Post":
    dbcon.addPost(post)

  test "addPost":
    # This also provides the posts we need.
    for post in genFakePosts():
      dbcon.addPost(post)
  
  test "postIdExists":
    assert dbcon.postIdExists(post.id), "Custom post apparently doesn't exist?"
  
  test "updatePost":
    # Let's change the post privacy level
    dbcon.updatePost(post.id, "level", "100")
    assert dbcon.getPost(post.id)[8] == "100"

    # Restore it so everything else won't run impacted,
    # and also this serves as an extra test
    dbcon.updatePost(post.id, "level", "0")
    assert dbcon.getPost(post.id)[8] == "0"
  
  test "getPost":
    # On the one hand, we shouldn't hard-code or encourage hardcoding database specifics
    # On the other hand, we are returning db rows when everything else is meant to be an abstraction.
    # So this serves as a nice way to test database compatability.
    # (And to serve as a barrier against regressions in the future)
    assert dbcon.getPost(post.id)[0] == post.id
    assert dbcon.getPost(post.id)[1] == "" # Recipients
    assert dbcon.getPost(post.id)[2] == post.sender
    assert dbcon.getPost(post.id)[3] == "" # Replyto
    assert dbcon.getPost(post.id)[4] != "" # Written
    assert dbcon.getPost(post.id)[5] == "f" # Modified
    assert dbcon.getPost(post.id)[6] == "t" # Local
    assert dbcon.getPost(post.id)[7] == "0" # Client
    assert dbcon.getPost(post.id)[8] == "0" # Post privacy level

  test "getPostIDsByUser (Without limit)":
    # Our sender shouldn't have an empty list.
    assert dbcon.getPostIDsByUser(post.sender, 0) != @[]
    # Let's see if this post is in this list.
    assert post.id in dbcon.getPostIDsByUser(post.sender, 0)

    # Let's test with a nonexistent user
    assert dbcon.getPostIDsByUser(randstr(1), 0) == @[]
    assert dbcon.getPostIDsByUser(randstr(1), 0).len() == 0
    assert dbcon.getPostIDsByUser(randstr(1), 0) != @[post.id]

  test "getPostIDsByUser (With limit)":
    # Our sender shouldn't have an empty list.
    assert dbcon.getPostIDsByUser(post.sender, 1) != @[]
    assert dbcon.getPostIDsByUser(post.sender, 1).len() == 1
    assert dbcon.getPostIDsByUser(post.sender, 1)[0] != "" # An empty item shouldn't be returned
    # It's not guaranteed that our post is in this list.
    # So we can't test for it reliably.