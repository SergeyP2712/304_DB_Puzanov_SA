PRAGMA foreign_keys = ON;
PRAGMA journal_mode = MEMORY;
PRAGMA synchronous = OFF;
PRAGMA temp_store = MEMORY;
PRAGMA cache_size = -16000;

DROP TABLE IF EXISTS tags;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS movie_genres;
DROP TABLE IF EXISTS movies;
DROP TABLE IF EXISTS genres;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    gender TEXT NOT NULL CHECK(gender IN ('male', 'female')),
    register_date TEXT,
    occupation TEXT
);

CREATE TABLE genres (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER
);

CREATE TABLE movie_genres (
    movie_id INTEGER NOT NULL,
    genre_id INTEGER NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id) REFERENCES genres(id) ON DELETE CASCADE
);

CREATE TABLE ratings (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL,
    timestamp INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE RESTRICT
);

CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    timestamp INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE RESTRICT
);

-- 1. Импорт сырых данных (ВНИМАНИЕ: в movies.csv всего 3 колонки!)
CREATE TEMPORARY TABLE raw_movies (id INTEGER, title TEXT, genres TEXT);
.mode csv
.import --skip 1 ../Task02/movies.csv raw_movies

CREATE TEMPORARY TABLE raw_ratings (id INTEGER, user_id INTEGER, movie_id INTEGER, rating REAL, timestamp INTEGER);
.import --skip 1 ../Task02/ratings.csv raw_ratings

CREATE TEMPORARY TABLE raw_tags (user_id INTEGER, movie_id INTEGER, tag TEXT, timestamp INTEGER);
.import --skip 1 ../Task02/tags.csv raw_tags

CREATE TEMPORARY TABLE raw_users (id INTEGER, name TEXT, email TEXT, gender TEXT, register_date TEXT, occupation TEXT);
.separator "|"
.import --skip 1 ../Task02/users.txt raw_users
.mode csv

-- 2. Заполнение основных таблиц
INSERT INTO users (id, name, email, gender, register_date, occupation)
SELECT id, name, email, gender, register_date, occupation FROM raw_users;

-- Извлекаем год из названия фильма, например "Toy Story (1995)" -> 1995
INSERT INTO movies (id, title, year)
SELECT id, title, 
       CASE 
           WHEN INSTR(title, '(') > 0 AND INSTR(title, ')') > 0 
           THEN CAST(SUBSTR(title, INSTR(title, '(') + 1, INSTR(title, ')') - INSTR(title, '(') - 1) AS INTEGER)
           ELSE NULL 
       END
FROM raw_movies;

-- 3. Разделение жанров (Рекурсивный CTE)
CREATE TEMPORARY TABLE split_genres AS
WITH RECURSIVE split(movie_id, genre, rest) AS (
    SELECT id,
        TRIM(CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, 1, INSTR(genres, '|') - 1) ELSE genres END),
        CASE WHEN INSTR(genres, '|') > 0 THEN SUBSTR(genres, INSTR(genres, '|') + 1) ELSE '' END
    FROM raw_movies WHERE genres IS NOT NULL AND genres != ''
    UNION ALL
    SELECT movie_id,
        TRIM(CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, 1, INSTR(rest, '|') - 1) ELSE rest END),
        CASE WHEN INSTR(rest, '|') > 0 THEN SUBSTR(rest, INSTR(rest, '|') + 1) ELSE '' END
    FROM split WHERE rest != ''
)
SELECT DISTINCT movie_id, genre FROM split;

-- 4. Заполнение справочника жанров и связей
INSERT INTO genres (name) SELECT DISTINCT genre FROM split_genres;

INSERT INTO movie_genres (movie_id, genre_id)
SELECT sg.movie_id, g.id
FROM split_genres sg
JOIN genres g ON g.name = sg.genre;

-- 5. Заполнение оценок и тегов
INSERT INTO ratings (id, user_id, movie_id, rating, timestamp)
SELECT id, user_id, movie_id, rating, timestamp 
FROM raw_ratings
WHERE rating >= 0 AND rating <= 5;

INSERT INTO tags (user_id, movie_id, tag, timestamp)
SELECT user_id, movie_id, tag, timestamp FROM raw_tags;

-- 6. Индексы
CREATE INDEX idx_users_name ON users(name);
CREATE INDEX idx_movies_title ON movies(title);
CREATE INDEX idx_movies_year ON movies(year);

-- 7. Очистка временных таблиц
DROP TABLE raw_movies;
DROP TABLE raw_ratings;
DROP TABLE raw_tags;
DROP TABLE raw_users;
DROP TABLE split_genres;

-- 8. Триггер для проверки рейтинга
CREATE TRIGGER check_rating_before_insert
BEFORE INSERT ON ratings
FOR EACH ROW
WHEN NEW.rating < 0 OR NEW.rating > 5
BEGIN
    SELECT RAISE(ABORT, 'Rating must be between 0 and 5');
END;