import quark/[users, posts, debug, db, crypto], quark/private/macros
import std/[unittest], rng

# Let's get started!
var dbcon = connectToDb()

echo "Dropping everything already in db"
dbcon.cleanDb()
echo"Setting up db again"
dbcon.setup()

# A post that we have full control over.
var post = newPostX(
  sender = "scout",
  content = @[text(sample(fakeStatuses))]
)
dbcon.addPost(post)

suite "Post-related tests":
  test "addPost":
    # This also provides the posts we need.
    for user in genFakeUsers():
      dbcon.addUser(user)
    for post in genFakePosts():
      dbcon.addPost(post)
  
  test "postIdExists":
    assert dbcon.postIdExists(post.id), "Custom post apparently doesn't exist?"
  
  test "updatePost":
    # Let's change id
    dbcon.updatePost(post.id, "id", "randomonium")
    assert dbcon.postIdExists("randomonium")
    # Restore it for consistency's sake, and as an extra test
    dbcon.updatePost("randomonium", "id", post.id)
    assert dbcon.postIdExists(post.id)

  
  test "getPost":
    # On the one hand, we shouldn't hard-code or encourage hardcoding database specifics
    # On the other hand, we are literally exposing database rows in a public APi.
    # So, we might as well *try* to be more backwards compatible.
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
  
  test "deleteUsers":
    assert dbcon.userHandleExists("katie") == false