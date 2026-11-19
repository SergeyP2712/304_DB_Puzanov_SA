INSERT INTO users (name, email, gender, occupation, register_date) VALUES
('Медведев Глеб', 'medvedev.gleb@gmail.com', 'male', 'student', datetime('now')),
('Мена Вера', 'mena.vera@gmail.com', 'male', 'student', datetime('now')),
('Пузанов Сергей', 'puzanov.sergey@gmail.com', 'male', 'student', datetime('now')),
('Рустамова Азиза', 'rustamova.aziza@gmail.com', 'female', 'student', datetime('now')),
('Семонченков Илья', 'semonchenkov.ilya@gmail.com', 'male', 'student', datetime('now'));

INSERT INTO movies (title, year) VALUES
('Interstellar', 2014),
('The Grand Budapest Hotel', 2014),
('Mad Max: Fury Road', 2015);

INSERT OR IGNORE INTO genres (name) VALUES ('Sci-Fi'), ('Comedy'), ('Action'), ('Adventure'), ('Drama');

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'Interstellar' AND g.name IN ('Sci-Fi', 'Adventure', 'Drama');

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'The Grand Budapest Hotel' AND g.name IN ('Comedy', 'Drama');

INSERT INTO movie_genres (movie_id, genre_id)
SELECT m.id, g.id FROM movies m, genres g 
WHERE m.title = 'Mad Max: Fury Road' AND g.name IN ('Action', 'Adventure', 'Sci-Fi');

INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 5.0, strftime('%s', 'now') 
FROM users u, movies m 
WHERE u.name = 'Пузанов Сергей' AND m.title = 'Interstellar';

INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 4.5, strftime('%s', 'now') 
FROM users u, movies m 
WHERE u.name = 'Пузанов Сергей' AND m.title = 'The Grand Budapest Hotel';

INSERT INTO ratings (user_id, movie_id, rating, timestamp)
SELECT u.id, m.id, 4.0, strftime('%s', 'now') 
FROM users u, movies m 
WHERE u.name = 'Пузанов Сергей' AND m.title = 'Mad Max: Fury Road';