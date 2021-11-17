-- PART 1 - INVESTIGATE THE EXISTING SCHEMA

-- 1. The id field from the post's table and post_id from the comment's table should have the same data type;
-- 2. Both upvotes and downvotes should be stored in a separated table;
-- 3. The schema should have a table for users. The link between the post and comment tables and the users table should be the user_id as a integer;
-- 4. We should have a separated table just for the topics;
-- 5. We should track the time when posts and comments are created;
-- 6. The data type "BIGINT" is way too big for the post_id;

-- PART 2 - CREATE THE DDL FOR YOUR NEW SCHEMA

-- A. Allow new users to register:
--      1. Each username has to be unique (OK)
--      2. Usernames can be composed of at most 25 characters (OK)
--      3. Usernames can’t be empty (OK)
--      4. We won’t worry about user passwords for this project (OK)

CREATE TABLE "users" (
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR(25) NOT NULL,
    "birth_date" DATE,
    "gender" VARCHAR(20),
    "last_login" TIMESTAMP,
    "created_at" TIMESTAMP,
    CONSTRAINT "username_not_empty" CHECK(LENGTH(TRIM("username")) > 0)
);

CREATE UNIQUE INDEX ON "users" (LOWER("username"));

CREATE INDEX "find_user_by_partial_username" ON "users" (
    LOWER("username") VARCHAR_PATTERN_OPS
);
CREATE INDEX "find_users_by_time" ON "users" ("created_at");

-- B. Allow registered users to create new topics:
--      1. Topic names have to be unique (OK)
--      2. The topic’s name is at most 30 characters (OK)
--      3. The topic’s name can’t be empty (OK)
--      4. Topics can have an optional description of at most 500 characters (OK)

CREATE TABLE "topics" (
    "id" SERIAL PRIMARY KEY,
    "topic" VARCHAR(30) NOT NULL,
    "description" VARCHAR(500),
    "created_at" TIMESTAMP,
    CONSTRAINT "topic_not_empty" CHECK(LENGTH(TRIM("topic")) > 0)
);

CREATE UNIQUE INDEX ON "topics" (LOWER("topic"));

CREATE INDEX "find_topics_by_partial_topic" ON "topics" (
    LOWER("topic") VARCHAR_PATTERN_OPS
);

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
    "topic_id" INTEGER NOT NULL,
    "user_id" INTEGER,
    "created_at" TIMESTAMP,
    FOREIGN KEY ("topic_id") REFERENCES "topics" ON DELETE CASCADE,
    FOREIGN KEY ("user_id") REFERENCES "users" ON DELETE SET NULL,
    CONSTRAINT "valid_content_type" CHECK ("content_type" = 'Text' OR "content_type" = 'Url'),
    CONSTRAINT "title_not_empty" CHECK (LENGTH(TRIM("title")) > 0)
);

CREATE INDEX "find_posts_by_user" ON "posts" ("user_id");
CREATE INDEX "find_posts_by_topic" ON "posts" ("topic_id");
CREATE INDEX "find_posts_by_url" ON "posts" ("content");

-- D. Allow registered users to create new posts on existing topics:
--      1. A comment’s text content can’t be empty. (OK)
--      2. Contrary to the current linear comments, the new structure should allow comment threads at arbitrary levels. (OK)
--      3. If a post gets deleted, all comments associated with it should be automatically deleted too (OK)
--      4. If the user who created the comment gets deleted, then the comment will remain, but it will become dissociated from that user. (OK)
--      5. If a comment gets deleted, then all its descendants in the thread structure should be automatically deleted too. (OK)

CREATE TABLE "comments" (
    "id" SERIAL PRIMARY KEY,
    "text_content" TEXT NOT NULL,
    "parent_id" INTEGER NULL,
    "post_id" INTEGER NOT NULL,
    "user_id" INTEGER,
    "created_at" TIMESTAMP,
    FOREIGN KEY ("post_id") REFERENCES "posts" ON DELETE CASCADE,
    FOREIGN KEY ("user_id") REFERENCES "users" ON DELETE SET NULL,
    FOREIGN KEY ("parent_id") REFERENCES comments(id) ON DELETE CASCADE,
    CONSTRAINT "text_content_not_empty" CHECK (LENGTH(TRIM("text_content")) > 0)
);

CREATE INDEX "find_top_comments_by_post" ON "comments" ("post_id");
CREATE INDEX "find_comments_by_parent" ON "comments" ("parent_id");
CREATE INDEX "find_comments_by_user" ON "comments" ("user_id");

-- E. Allow registered users to create new posts on existing topics:
--      1. Hint: you can store the (up/down) value of the vote as the values 1 and -1 respectively. (OK)
--      2. If the user who cast a vote gets deleted, then all their votes will remain, but will become dissociated from the user (OK)
--      3. If a post gets deleted, then all the votes for that post should be automatically deleted too (OK)

CREATE TABLE "votes" (
    "id" SERIAL PRIMARY KEY,
    "vote" SMALLINT,
    "user_id" INTEGER,
    "post_id" INTEGER NOT NULL,
    "created_at" TIMESTAMP,
    FOREIGN KEY ("post_id") REFERENCES "posts" ON DELETE CASCADE,
    FOREIGN KEY ("user_id") REFERENCES "users" ON DELETE SET NULL,
    CONSTRAINT "unique_vote" UNIQUE("user_id", "post_id")
    CONSTRAINT "valid_vote" CHECK ("vote" = 1 OR "vote" = -1 )
);

-- Compute the score of a post, defined as the difference between the number of upvotes and the number of downvotes

CREATE VIEW "post_score" AS (
    SELECT
        post_id,
        SUM(vote)
    FROM votes
    GROUP BY 1
    ORDER BY 2 DESC, 1
);

-- GUIDELINE

--      1.	List all users who haven’t logged in the last year. (OK)
--      2.	List all users who haven’t created any post. (OK)
--      3.	Find a user by their username. (OK)
--      4.	List all topics that don’t have any posts. (OK)
--      5.	Find a topic by its name. (OK)
--      6.	List the latest 20 posts for a given topic. (OK)
--      7.	List the latest 20 posts made by a given user. (OK)
--      8.	Find all posts that link to a specific URL, for moderation purposes. (OK)
--      9.	List all the top-level comments (those that don’t have a parent comment for a given post). (OK)
--      10.	List all the direct children of a parent comment. (OK)
--      11.	List the latest 20 comments made by a given user. (OK)
--      12.	Compute the score of a post, defined as the difference between the number of upvotes and the number of downvotes. (OK)
--      13. You’ll need to use normalization, various constraints, as well as indexes in your new database schema. You should use named constraints and indexes to make your schema cleaner (OK)
--      14. Your new database schema will be composed of five (5) tables that should have an auto-incrementing id as their primary key. (OK)

-- PART 3: MIGRATE THE PROVIDED DATA

--      1.	Topic descriptions can all be empty (OK)
--      2.	Since the bad_comments table doesn’t have the threading feature, you can migrate all comments as top-level comments, i.e. without a parent (OK)
--      3.	You can use the Postgres string function regexp_split_to_table to unwind the comma-separated votes values into separate rows (OK)
--      4.	Don’t forget that some users only vote or comment, and haven’t created any posts. You’ll have to create those users too. (OK)
--      5.	The order of your migrations matter! For example, since posts depend on users and topics, you’ll have to migrate the latter first. (OK)
--      6.	Tip: You can start by running only SELECTs to fine-tune your queries, and use a LIMIT to avoid large data sets. Once you know you have the correct query, you can then run your full INSERT...SELECT query. (OK)
--      7.	Note: The data in your SQL Workspace contains thousands of posts and comments. The DML queries may take at least 10-15 seconds to run. (OK)

-- First Step: Create the topic's table

INSERT INTO "topics" ("topic")
    SELECT DISTINCT
    	INITCAP(topic) -- INITCAP: Makes the first letter of each word uppercase
    FROM bad_posts
    ORDER BY 1;

-- Second Step: Create user's table

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

-- Third Step: Create post's table

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

-- Forth Step: Create comment's table

INSERT INTO "comments" ("id","text_content","post_id", "user_id")
    SELECT
    	bc.id AS id,
    	bc.text_content AS text_content,
    	bc.post_id AS post_id,
    	u.id AS user_id
    FROM bad_comments AS bc
    JOIN users AS u
    ON bc.username = u.username;

-- Fifth Step: Create vote's table

INSERT INTO "votes" ("vote", "user_id", "post_id")
    WITH sub AS (
        SELECT
            regexp_split_to_table(upvotes,',') AS username,
            1 AS vote,
            id AS post_id
        FROM bad_posts
        UNION ALL
        SELECT
            regexp_split_to_table(downvotes,',') AS username,
            -1 AS vote,
            id AS post_id
        FROM bad_posts
        ORDER BY 3,2,1
    )
    SELECT
        s.vote AS vote,
        u.id AS user_id,
        s.post_id AS post_id
    FROM sub AS s
    JOIN users AS u
    ON s.username = u.username;



-- DROP TABLE "votes";
-- DROP TABLE "comments";
-- DROP TABLE "posts";
-- DROP TABLE "topics";
-- DROP TABLE "users";

-- DROP VIEW "post_score";
