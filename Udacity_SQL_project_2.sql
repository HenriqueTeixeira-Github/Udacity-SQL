-- PART 1 - INVESTIGATE THE EXISTING SCHEMA

-- id from post and post_id from comments should have the same type
-- upvotes and downvotes should be in a separeted table
-- it should have a user table and this table and the link between the post and comment tables should be the user_id as a integer
-- We should have a table for topics
--  We hould have a table for users

-- PART 2 - CREATE THE DDL FOR YOUR NEW SCHEMA

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

-- GUIDELINE

--      1.	List all users who haven’t logged in in the last year.
--      2.	List all users who haven’t created any post.
--      3.	Find a user by their username.
--      4.	List all topics that don’t have any posts.
--      5.	Find a topic by its name.
--      6.	List the latest 20 posts for a given topic.
--      7.	List the latest 20 posts made by a given user.
--      8.	Find all posts that link to a specific URL, for moderation purposes.
--      9.	List all the top-level comments (those that don’t have a parent comment) for a given post.
--      10.	List all the direct children of a parent comment.
--      11.	List the latest 20 comments made by a given user.
--      12.	Compute the score of a post, defined as the difference between the number of upvotes and the number of downvotes

--      13. You’ll need to use normalization, various constraints, as well as indexes in your new database schema. You should use named constraints and indexes to make your schema cleaner

--      14. Your new database schema will be composed of five (5) tables that should have an auto-incrementing id as their primary key.

-- PART 3: MIGRATE THE PROVIDED DATA

--      1.	Topic descriptions can all be empty
--      2.	Since the bad_comments table doesn’t have the threading feature, you can migrate all comments as top-level comments, i.e. without a parent
--      3.	You can use the Postgres string function regexp_split_to_table to unwind the comma-separated votes values into separate rows
--      4.	Don’t forget that some users only vote or comment, and haven’t created any posts. You’ll have to create those users too.
--      5.	The order of your migrations matter! For example, since posts depend on users and topics, you’ll have to migrate the latter first.
--      6.	Tip: You can start by running only SELECTs to fine-tune your queries, and use a LIMIT to avoid large data sets. Once you know you have the correct query, you can then run your full INSERT...SELECT query.
--      7.	Note: The data in your SQL Workspace contains thousands of posts and comments. The DML queries may take at least 10-15 seconds to run.
