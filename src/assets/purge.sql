-- Same exact convention as setup.sql
-- Which is why this looks so weird.
-- We could instruct our program to run a SQL command on every line
-- But I'd rather re-use the interpreter we just made
-- Even if it makes this a bit ugly.
DROP TABLE IF EXISTS meta CASCADE;

DROP TABLE IF EXISTS users CASCADE;

DROP TABLE IF EXISTS apps CASCADE;

DROP TABLE IF EXISTS posts CASCADE;

DROP TABLE IF EXISTS post_texts CASCADE;

DROP TABLE IF EXISTS post_embeds CASCADE;

DROP TABLE IF EXISTS reactions CASCADE;

DROP TABLE IF EXISTS boosts CASCADE;

DROP TABLE IF EXISTS tag CASCADE;

DROP TABLE IF EXISTS fields CASCADE;

DROP TABLE IF EXISTS bookmarks CASCADE;

DROP TABLE IF EXISTS logins CASCADE;

DROP TABLE IF EXISTS auth_codes CASCADE;

DROP TABLE IF EXISTS email_codes CASCADE;

DROP TABLE IF EXISTS oauth_tokens CASCADE;

DROP TABLE IF EXISTS user_follows CASCADE;

DROP TABLE IF EXISTS tag_follows CASCADE;