-- UTF-8 is best.
SET client_encoding = 'UTF8';

-- Needed to work around https://github.com/nim-lang/db_connector/issues/19
-- Without this, it might be possible to do SQL injection.
-- TODO: Fix this in the db_connector library so that everyone can enjoy injection-free data operations.
SET standard_conforming_strings = on;


CREATE TABLE apps IF NOT EXISTS (
  id TEXT PRIMARY KEY NOT NULL UNIQUE, -- The client Id for the application
  secret TEXT NOT NULL UNIQUE,  -- The client secret for the application
  scopes TEXT NOT NULL, -- Scopes of this application, space-separated.
  redirect_uri TEXT DEFAULT 'urn:ietf:wg:oauth:2.0:oob', -- The redirect uri for the app
  name TEXT, -- Name of application
  link TEXT, -- The homepage or source code link to the application
  last_accessed TIMESTAMP, -- Last used timestamp, when this is older than 2 weeks, the row is deleted.
);


-- TODO: Separate a user's handle into two components.
-- A username and a domain.
-- Or, do this only if there are any benefits to be gained.
CREATE TABLE users IF NOT EXISTS (
  id TEXT PRIMARY KEY NOT NULL, -- The user ID
  kind TEXT NOT NULL, -- The user type, see UserType object in user.nim
  handle TEXT UNIQUE NOT NULL, -- The user's actual username (Fx. alice@alice.wonderland)
  name TEXT DEFAULT 'New User', -- The user's display name (Fx. Alice)
  local BOOLEAN NOT NULL, -- A boolean indicating whether the user originates from the local server or another one.
  email TEXT, -- The user's email (Empty for remote users)
  bio TEXT, -- The user's biography 
  password TEXT, -- The user's hashed & salted password (Empty for remote users obv)
  salt TEXT, -- The user's salt (Empty for remote users obv)
  kdf INTEGER NOT NULL, -- The version of the key derivation function. See DESIGN.md's Key derivation function table for more.
  admin BOOLEAN NOT NULL DEFAULT FALSE, -- A boolean indicating whether or not this user is an Admin.
  moderator BOOLEAN NOT NULL DEFAULT FALSE, -- A boolean indicating whether or not this user is a Moderator.
  discoverable BOOLEAN NOT NULL DEFAULT TRUE, -- A boolean indicating whether or not this user is discoverable in frontends
  is_frozen BOOLEAN NOT NULL, -- A boolean indicating whether this user is frozen (Posts from this user will not be stored)
  is_verified BOOLEAN NOT NULL, -- A boolean indicating whether this user's email address has been verified (NOT the same as an approval)
  is_approved BOOLEAN NOT NULL, -- A boolean indicating if the user hs been approved by an administrator
);

CREATE TABLE posts_content IF NOT EXISTS (
  pid TEXT PRIMARY KEY NOT NULL, -- The post ID for the content.
  
  -- The specific kind of content it is
  -- 0 is for text for example, 1 could be for polls.
  -- Read the quark src obvs, I could be wrong about this.
  kind smallint NOT NULL DEFAULT 0, 
  cid TEXT DEFAULT '', -- The id for the content, if applicable.

  -- Some foreign keys for integrity
  foreign key (pid) references posts(id),
);

-- TODO: Add support for other formats such as HTML, Markdown, Rst and so on.
-- It could be done with separate tables (Overkill) or a column dictating the format.
CREATE TABLE posts_text IF NOT EXISTS (
  pid TEXT PRIMARY KEY NOT NULL, -- The post id that the best belongs to
  content TEXT NOT NULL, -- The text content itself
  published TIMESTAMP NOT NULL, -- The date that this content was published
  latest BOOLEAN NOT NULL DEFAULT TRUE, -- Whether or not this is the latest post
  foreign key (pid) references posts(id), -- Some foreign keys for integrity
);

CREATE TABLE posts IF NOT EXISTS (
  id TEXT PRIMARY KEY NOT NULL, -- The Post id
  recipients TEXT, -- A comma-separated list of recipients since postgres arrays are a nightmare.
  sender TEXT NOT NULL, -- A string containing the sender's id
  replyto TEXT DEFAULT '', -- A string containing the post that the sender is replying to, if at all.
  written TIMESTAMP NOT NULL, -- A timestamp containing the date that the post was originally written (and published)
  modified BOOLEAN NOT NULL DEFAULT FALSE, -- A boolean indicating whether the post was modified or not.
  local BOOLEAN NOT NULL, -- A boolean indicating whether the post originated from this server or other servers.
  client TEXT NOT NULL DEFAULT '0', -- The client that sent the post
  
  -- The privacy level for the post
  -- the level dictates who is allowed to see the post and whatnot.
  -- such as for example, if it is a direct message.
  level smallint NOT NULL DEFAULT 0, 

  -- Foreign keys for database integrity
  foreign key (sender) references users(id),
  foreign key (client) references apps(id),
);

CREATE TABLE reactions IF NOT EXISTS (
  pid TEXT NOT NULL, -- ID of post that the user reacted to
  uid TEXT NOT NULL, -- ID of user who reacted to that post
  reaction TEXT NOT NULL,  -- Specific reaction, could be favorite or the shortcode of an emoji.
  
  -- Some foreigns key for integrity
  foreign key (pid) references posts(id), 
  foreign key (uid) references users(id),
)

CREATE TABLE follows IF NOT EXISTS (
  follower TEXT NOT NULL, -- ID of user that is following
  following TEXT NOT NULL, -- ID of the user that is being followed
  approved BOOLEAN NOT NULL, -- Whether or not the follow has gone-through, ie. if its approved

  -- Foreign keys for database integrity
  foreign key (follower) references users(id),
  foreign key (following) references users(id),
);

CREATE TABLE boosts IF NOT EXISTS (
  pid TEXT NOT NULL, -- ID of post that user boosted
  uid TEXT NOT NULL, -- ID of user that boosted post
  level TEXT NOT NULL, -- The boost level, ie. is it followers-only or whatever.

  -- Some foreign keys for integrity
  foreign key (pid) references posts(id), 
  foreign key (uid) references users(id),
);

CREATE TABLE fields IF NOT EXISTS (
  key TEXT NOT NULL, -- The key part of the field
  value TEXT NOT NULL, -- The value part of the field.
  uid TEXT NOT NULL, -- Which user has created this profile field

  -- TODO: This is poorly implemented, we don't even store the domain we need to verify...
  verified BOOLEAN DEFAULT FALSE, -- A boolean indicating if the profile field has been verified, fx. domain verification and so on.
  verified_at TIMESTAMP, -- A timestamp for when the field was verified

  -- A foreign key for integrity
  foreign key (uid) references users(id),
);

CREATE TABLE sessions IF NOT EXISTS (
  id TEXT PRIMARY KEY UNIQUE NOT NULL, -- The id for the session, aka. the session token itself
  uid TEXT NOT NULL, -- User ID for the session
  last_used TIMESTAMP NOT NULL, -- When the session was last used.

   -- A foreign key for some database integrity
  foreign key (uid) references users(id)
);

CREATE TABLE auth_codes IF NOT EXISTS (
  id TEXT PRIMARY KEY NOT NULL, -- The code itself (also acts as an id in this case)
  uid TEXT NOT NULL, -- The user id associated with this code.
  cid TEXT NOT NULL, -- The client id associated with this code.
  scopes TEXT DEFAULT 'read', -- The scopes that were requested

  -- Some foreign keys for integrity
  foreign key (cid) references apps(id), 
  foreign key (uid) references users(id)
);

CREATE TABLE oauth IF NOT EXISTS (
  id TEXT PRIMARY KEY NOT NULL UNIQUE, -- The oauth token
  uses_code BOOLEAN DEFAULT 'false', -- The type of token.
  code TEXT UNIQUE, -- The oauth code that was generated for this token
  cid TEXT NOT NULL, -- The client id of the app that this token belongs to
  last_use TIMESTAMP NOT NULL, -- Anything older than a week will be cleared out

  -- Some foreign keys for integrity
  foreign key (code) references auth_codes(id),
  foreign key (cid) references apps(id)
);

CREATE TABLE email_codes IF NOT EXISTS (
  id TEXT PRIMARY KEY NOT NULL UNIQUE, -- The email code
  uid TEXT NOT NULL UNIQUE, -- The user it belongs to
  date TIMESTAMP NOT NULL, -- The date it was created

   -- A foreign key for database integrity
  foreign key (uid) references users(id)
);

CREATE TABLE bookmarks IF NOT EXISTS (
  pid TEXT NOT NULL, -- The post being bookmarked
  uid TEXT NOT NULL, -- The user who bookmarked the post

  -- Some foreign keys for integrity
  foreign key (uid) references users(id), 
  foreign key (pid) references posts(id)
);

-- Add a null user for when users are deleted.
INSERT INTO users VALUES ('null', 'Person', 'null', 'Deleted User', TRUE, 'Deleted User', '', '', '100', FALSE, FALSE, FALSE, TRUE, FALSE, FALSE) ON CONFLICT (users) DO NOTHING;

-- Make a null app client
INSERT INTO apps VALUES ('0', '0', 'read', '', '', '', '1970-01-01');

-- Create an index on the post table to speed up post by user searches.
CREATE INDEX IF NOT EXISTS snd_idx ON posts USING btree (sender);