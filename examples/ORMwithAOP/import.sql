insert into Post (title, body, postDate) VALUES ('ColdSpring AOP with ORM Example', 'This is a blog post about how you can use ORM and AOP together. Pretty neat, ''eh?', '2012-08-08 19:54:13');
insert into Post (title, body, postDate) VALUES ('Here is another blog post', 'I wanted to write another blog post, just because the single one on it''s own seemed kind of lonely', '2012-08-09 06:24:11');
insert into Comment (name, comment, postDate, postid) VALUES ('John Smith', 'This is the best blog post I''ve ever seen in my life!', '2012-08-09 05:24:26', (select id from Post where title = 'ColdSpring AOP with ORM Example'));
insert into Comment (name, comment, postDate, postid) VALUES ('Jane Doe', 'How do you write this sort of amazing stuff! It''s incredible', '2012-08-10 06:33:26', (select id from Post where title = 'ColdSpring AOP with ORM Example'));