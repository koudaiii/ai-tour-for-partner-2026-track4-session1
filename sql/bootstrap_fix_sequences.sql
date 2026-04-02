SELECT setval('users_id_seq', COALESCE((SELECT MAX(id) FROM users), 0) + 1, false);
SELECT setval('posts_id_seq', COALESCE((SELECT MAX(id) FROM posts), 0) + 1, false);
SELECT setval('comments_id_seq', COALESCE((SELECT MAX(id) FROM comments), 0) + 1, false);
