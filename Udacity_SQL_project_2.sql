-- PART 1

-- id from post and post_id from comments should have the same type
-- upvotes and downvotes should be in a separeted table
-- it should have a user table and this table and the link between the post and comment tables should be the user_id as a integer
-- We should have a table for topics
--  We hould have a table for users

-- PART 2

-- A. Allow new users to register:
--      1. Each username has to be unique
--      2. Usernames can be composed of at most 25 characters
--      3. Usernames can’t be empty
--      4. We won’t worry about user passwords for this project

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(25) UNIQUE NOT NULL,
    birth_date DATE NOT NULL,
    gender VARCHAR(20),
    last_login TIMESTAMP,
    created_at TIMESTAMP,
)

-- B. Allow registered users to create new topics:
--      1. Topic names have to be unique
--      2. The topic’s name is at most 30 characters
--      3. The topic’s name can’t be empty
--      4. Topics can have an optional description of at most 500 characters

CREATE TABLE topics (
    id SERIAL PRIMARY KEY,
    topic VARCHAR(30) UNIQUE NOT NULL,
    description VARCHAR(500)
)

-- C. Allow registered users to create new posts on existing topics:
--      1. Posts have a required title of at most 100 characters
--      2. The title of a post can’t be empty
--      3. Posts should contain either a URL or a text content, but not both
--      4. If a topic gets deleted, all the posts associated with it should be automatically deleted too
--      5. If the user who created the post gets deleted, then the post will remain, but it will become dissociated from that user

CREATE TABLE posts (
    id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    content TEXT,
    content_type VARCHAR(10), -- TEXT OR URL
    topic_id INTEGER,
    user_id INTEGER
)

-- D. Allow registered users to create new posts on existing topics:
--      1. A comment’s text content can’t be empty.
--      2. Contrary to the current linear comments, the new structure should allow comment threads at arbitrary levels.
--      3. If a post gets deleted, all comments associated with it should be automatically deleted too
--      4. If the user who created the comment gets deleted, then the comment will remain, but it will become dissociated from that user.
--      5. If a comment gets deleted, then all its descendants in the thread structure should be automatically deleted too

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    comment TEXT NOT NULL,
    comment_id INTEGER,
    post_id INTEGER,
    user_id INTEGER,
)

-- E. Allow registered users to create new posts on existing topics:
--      1. Hint: you can store the (up/down) value of the vote as the values 1 and -1 respectively.
--      2. If the user who cast a vote gets deleted, then all their votes will remain, but will become dissociated from the user
--      3. If a post gets deleted, then all the votes for that post should be automatically deleted too

CREATE TABLE vote (
    id SERIAL PRIMARY KEY,
    vote TINYINT,
    user_id INTEGER,
    post_id INTEGER
)
