CREATE TABLE IF NOT EXISTS users (
  id BLOB PRIMARY KEY,
	handle VARCHAR(65535) UNIQUE NOT NULL,
  name VARCHAR(65535) NOT NULL,
  local BOOLEAN, 
	email VARCHAR(255),
  bio VARCHAR(65535),
  password VARCHAR(65535) NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
  id BLOB PRIMARY KEY,
  sender VARCHAR(65535) NOT NULL,
	written TIMESTAMP NOT NULL,
  updated TIMESTAMP,
	recipients VARCHAR(65535),
  post VARCHAR(65535) NOT NULL
);

-- Inserting some generic users for testing
-- The "users" table should be able to handle any user
-- even if they are not from this server
INSERT INTO users (id, handle, name, local, email, bio, password) VALUES ("1", "kropotkin", "Peter Kropotkin", true, "peter.kropotkin@moscow.commune.i2p","I love to help others and I inspire people to help each other\nI thought I might explore this platform\nI don't know how it works!", "BetterBlackANDRed");

INSERT INTO users (id, handle, name, local, email, bio, password) VALUES ("2", "lenin@communism.rocks", "Vladimir Lenin", false, "vladimir.lenin@cp.su", "Chairman of the Council of People's Commissars of the Soviet Union\n\nAny comments that are negative of the CCCP or CPSU will be reported.", "BetterRedThanDead");

INSERT INTO users (id, handle, name, local, email, bio, password) VALUES ("3", "aynrand@google.google","Ayn Rand", false, "aynrand@aynrand.google.site","\nAuthor of The Fountainhead and Atlas Shrugged.\nSocial democrats, socialists, communists, anarchists or anyone who has morals:\nDo not interact or you will be reported to Google's Unsafe Persons Registry.","BetterDeadThanRed");