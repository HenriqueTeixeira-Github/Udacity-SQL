-- PART 1 - INVESTIGATE THE EXISTING SCHEMA

-- id from post and post_id from comments should have the same type
-- upvotes and downvotes should be in a separeted table
-- it should have a user table and this table and the link between the post and comment tables should be the user_id as a integer
-- We should have a table for topics
--  We hould have a table for users

-- PART 2 - CREATE THE DDL FOR YOUR NEW SCHEMA

-- A. Allow new users to register:
--      1. Each username has to be unique (OK)
--      2. Usernames can be composed of at most 25 characters (OK)
--      3. Usernames can’t be empty (OK)
--      4. We won’t worry about user passwords for this project (OK)

CREATE TABLE "users" (
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR(25) UNIQUE NOT NULL,
    "birth_date" DATE,
    "gender" VARCHAR(20),
    "last_login" TIMESTAMP,
    "created_at" TIMESTAMP
);

-- B. Allow registered users to create new topics:
--      1. Topic names have to be unique (OK)
--      2. The topic’s name is at most 30 characters (OK)
--      3. The topic’s name can’t be empty (OK)
--      4. Topics can have an optional description of at most 500 characters (OK)

CREATE TABLE "topics" (
    "id" SERIAL PRIMARY KEY,
    "topic" VARCHAR(30) UNIQUE NOT NULL,
    "description" VARCHAR(500)
)

-- C. Allow registered users to create new posts on existing topics:
--      1. Posts have a required title of at most 100 characters (OK)
--      2. The title of a post can’t be empty (OK)
--      3. Posts should contain either a URL or a text content, but not both (OK)
--      4. If a topic gets deleted, all the posts associated with it should be automatically deleted too (OK)
--      5. If the user who created the post gets deleted, then the post will remain, but it will become dissociated from that user (OK)

CREATE TABLE "posts" (
    "id" SERIAL PRIMARY KEY,
    "title" VARCHAR(100) NOT NULL,
    "content" TEXT,
    "content_type" VARCHAR(10), -- TEXT OR URL
    "topic_id" INTEGER,
    "user_id" INTEGER,
    FOREIGN KEY ("topic_id") REFERENCES "topics" ON DELETE CASCADE,
    FOREIGN KEY ("user_id") REFERENCES "users" ON DELETE SET NULL
)

-- D. Allow registered users to create new posts on existing topics:
--      1. A comment’s text content can’t be empty. (OK)
--      2. Contrary to the current linear comments, the new structure should allow comment threads at arbitrary levels. (OK)
--      3. If a post gets deleted, all comments associated with it should be automatically deleted too
--      4. If the user who created the comment gets deleted, then the comment will remain, but it will become dissociated from that user.
--      5. If a comment gets deleted, then all its descendants in the thread structure should be automatically deleted too

CREATE TABLE "comments" (
    "id" SERIAL PRIMARY KEY,
    "comment" TEXT NOT NULL,
    "comment_id" INTEGER NULL,
    "post_id" INTEGER,
    "user_id" INTEGER,
    FOREIGN KEY ("post_id") REFERENCES "posts" ON DELETE CASCADE,
    FOREIGN KEY ("user_id") REFERENCES "users" ON DELETE SET NULL,
    FOREIGN KEY ("comment_id") REFERENCES comments(id) ON DELETE CASCADE
);

-- E. Allow registered users to create new posts on existing topics:
--      1. Hint: you can store the (up/down) value of the vote as the values 1 and -1 respectively. (OK)
--      2. If the user who cast a vote gets deleted, then all their votes will remain, but will become dissociated from the user (OK)
--      3. If a post gets deleted, then all the votes for that post should be automatically deleted too (OK)

CREATE TABLE "vote" (
    "id" SERIAL PRIMARY KEY,
    "vote" TINYINT CHECK ("vote" = 1 OR "vote" = -1 ),
    "user_id" INTEGER,
    "post_id" INTEGER,
    FOREIGN KEY ("post_id") REFERENCES "posts" ON DELETE CASCADE,
    FOREIGN KEY ("user_id") REFERENCES "users" ON DELETE SET NULL
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

--      14. Your new database schema will be composed of five (5) tables that should have an auto-incrementing id as their primary key. (OK)

-- PART 3: MIGRATE THE PROVIDED DATA

--      1.	Topic descriptions can all be empty (OK)
--      2.	Since the bad_comments table doesn’t have the threading feature, you can migrate all comments as top-level comments, i.e. without a parent
--      3.	You can use the Postgres string function regexp_split_to_table to unwind the comma-separated votes values into separate rows
--      4.	Don’t forget that some users only vote or comment, and haven’t created any posts. You’ll have to create those users too.
--      5.	The order of your migrations matter! For example, since posts depend on users and topics, you’ll have to migrate the latter first.
--      6.	Tip: You can start by running only SELECTs to fine-tune your queries, and use a LIMIT to avoid large data sets. Once you know you have the correct query, you can then run your full INSERT...SELECT query.
--      7.	Note: The data in your SQL Workspace contains thousands of posts and comments. The DML queries may take at least 10-15 seconds to run.

-- First Step: Create the Topic's table

INSERT INTO "topics" ("topic")
    SELECT DISTINCT
    	INITCAP(topic) -- INITCAP: Makes the first letter of each word uppercase
    FROM bad_posts
    ORDER BY 1;

-- Second Step: Create User's table

INSERT INTO "users" ("username")
    SELECT
    	username
    FROM bad_posts
    UNION
        SELECT
        	username
        FROM bad_comments
    UNION
        SELECT
        	regexp_split_to_table(upvotes,',')
        FROM bad_posts
    UNION
        SELECT
            regexp_split_to_table(downvotes,',')
        FROM bad_posts
    ORDER BY 1;

-- Third Step: Create Post's table

INSERT INTO "posts" ("id","title","content","content_type","topic_id","user_id")
    SELECT
    	bp.id AS id,
    	LEFT(bp.title,100) AS title,
    	CONCAT(bp.url,text_content) AS content,
    	CASE
    		WHEN bp.url IS NOT NULL THEN 'Url'
    		WHEN bp.text_content IS NOT NULL THEN 'Text'
    		ELSE ''
    	END AS content_type,
        t.id AS topic_id,
        u.id AS user_id
    FROM bad_posts AS bp
    JOIN users AS u
    ON bp.username = u.username
    JOIN topics AS t
    ON INITCAP(bp.topic) = t.topic
    ORDER BY 1;

-- Forth Step: Create Comment's tables

INSERT INTO "comments" ("id","comment","post_id", "user_id")
    SELECT
    	bc.id AS id,
    	bc.text_content AS comment,
    	bc.post_id AS post_id,
    	u.id AS user_id
    FROM bad_comments AS bc
    JOIN users AS u
    ON bc.username = u.username
