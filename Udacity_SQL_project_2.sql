-- PART 1

-- id from post and post_id from comments should have the same type
-- upvotes and downvotes should be in a separeted table
-- it should have a user table and this table and the link between the post and comment tables should be the user_id as a integer
-- We should have a table for topics
--  We hould have a table for users

-- PART 2

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(25) UNIQUE NOT NULL,
    birth_date DATE NOT NULL,
    gender VARCHAR(20),
    last_login TIMESTAMP,
    created_at TIMESTAMP,
)

CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    topic VARCHAR(30) UNIQUE NOT NULL,
    description VARCHAR(500)
)

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    content TEXT,
    content_type VARCHAR(10), -- TEXT OR URL
    topic_id INTEGER,
    user_id INTEGER
)

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    comment TEXT NOT NULL,
    comment_id INTEGER,
    post_id INTEGER,
    user_id INTEGER,
)

CREATE TABLE vote (
    id SERIAL PRIMARY KEY,
    vote TINYINT,
    user_id INTEGER,
    post_id INTEGER
)
