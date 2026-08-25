-- ============================================================
-- IMDB Database Design
-- Run this in the MySQL Shell / command prompt:
--   mysql -u root -p < imdb.sql
-- or paste section by section into the MySQL Shell.
-- ============================================================

-- Create and select the database
DROP DATABASE IF EXISTS IMDB;
CREATE DATABASE IMDB;
USE IMDB;

-- ============================================================
-- Core tables
-- ============================================================

-- Movie: the central entity
CREATE TABLE Movie (
    movie_id      INT AUTO_INCREMENT PRIMARY KEY,
    title         VARCHAR(150) NOT NULL,
    release_year  YEAR,
    duration_min  INT,
    rating        DECIMAL(3,1)          -- e.g. 8.5
);

-- User: people who write reviews
CREATE TABLE User (
    user_id    INT AUTO_INCREMENT PRIMARY KEY,
    username   VARCHAR(50) NOT NULL UNIQUE,
    email      VARCHAR(100) NOT NULL UNIQUE,
    joined_on  DATE
);

-- Artist: actors, directors, etc.
CREATE TABLE Artist (
    artist_id   INT AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    birth_date  DATE,
    country     VARCHAR(50)
);

-- Genre: lookup table for genres
CREATE TABLE Genre (
    genre_id   INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(50) NOT NULL UNIQUE
);

-- Skill: lookup table for artist skills
CREATE TABLE Skill (
    skill_id   INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(50) NOT NULL UNIQUE
);

-- Role: lookup table for roles an artist can perform (Actor, Director, etc.)
CREATE TABLE Role (
    role_id    INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(50) NOT NULL UNIQUE
);

-- ============================================================
-- Requirement 1: A movie can have multiple media (video or image)
-- ============================================================
CREATE TABLE Media (
    media_id    INT AUTO_INCREMENT PRIMARY KEY,
    movie_id    INT NOT NULL,
    media_type  ENUM('Video', 'Image') NOT NULL,
    url         VARCHAR(255) NOT NULL,
    CONSTRAINT fk_media_movie
        FOREIGN KEY (movie_id) REFERENCES Movie(movie_id)
        ON DELETE CASCADE
);

-- ============================================================
-- Requirement 2: A movie can belong to multiple genres (many-to-many)
-- ============================================================
CREATE TABLE Movie_Genre (
    movie_id   INT NOT NULL,
    genre_id   INT NOT NULL,
    PRIMARY KEY (movie_id, genre_id),
    CONSTRAINT fk_mg_movie
        FOREIGN KEY (movie_id) REFERENCES Movie(movie_id) ON DELETE CASCADE,
    CONSTRAINT fk_mg_genre
        FOREIGN KEY (genre_id) REFERENCES Genre(genre_id) ON DELETE CASCADE
);

-- ============================================================
-- Requirement 3: A movie can have multiple reviews,
--                and each review belongs to a user
-- ============================================================
CREATE TABLE Review (
    review_id    INT AUTO_INCREMENT PRIMARY KEY,
    movie_id     INT NOT NULL,
    user_id      INT NOT NULL,
    review_text  TEXT,
    score        DECIMAL(3,1),
    created_on   DATE,
    CONSTRAINT fk_review_movie
        FOREIGN KEY (movie_id) REFERENCES Movie(movie_id) ON DELETE CASCADE,
    CONSTRAINT fk_review_user
        FOREIGN KEY (user_id) REFERENCES User(user_id) ON DELETE CASCADE
);

-- ============================================================
-- Requirement 4: An artist can have multiple skills (many-to-many)
-- ============================================================
CREATE TABLE Artist_Skill (
    artist_id  INT NOT NULL,
    skill_id   INT NOT NULL,
    PRIMARY KEY (artist_id, skill_id),
    CONSTRAINT fk_as_artist
        FOREIGN KEY (artist_id) REFERENCES Artist(artist_id) ON DELETE CASCADE,
    CONSTRAINT fk_as_skill
        FOREIGN KEY (skill_id) REFERENCES Skill(skill_id) ON DELETE CASCADE
);

-- ============================================================
-- Requirement 5: An artist can perform multiple roles in a single film
--   The composite PK (movie_id, artist_id, role_id) allows the same
--   artist to appear in the same movie under different roles
--   (e.g. both Actor and Director).
-- ============================================================
CREATE TABLE Movie_Cast (
    movie_id   INT NOT NULL,
    artist_id  INT NOT NULL,
    role_id    INT NOT NULL,
    PRIMARY KEY (movie_id, artist_id, role_id),
    CONSTRAINT fk_cast_movie
        FOREIGN KEY (movie_id) REFERENCES Movie(movie_id) ON DELETE CASCADE,
    CONSTRAINT fk_cast_artist
        FOREIGN KEY (artist_id) REFERENCES Artist(artist_id) ON DELETE CASCADE,
    CONSTRAINT fk_cast_role
        FOREIGN KEY (role_id) REFERENCES Role(role_id) ON DELETE CASCADE
);

-- ============================================================
-- Sample data
-- ============================================================

-- Movies
INSERT INTO Movie (title, release_year, duration_min, rating) VALUES
('Inception',      2010, 148, 8.8),
('The Dark Knight',2008, 152, 9.0),
('Interstellar',   2014, 169, 8.6);

-- Users
INSERT INTO User (username, email, joined_on) VALUES
('alice', 'alice@example.com', '2023-01-10'),
('bob',   'bob@example.com',   '2023-03-22');

-- Artists
INSERT INTO Artist (name, birth_date, country) VALUES
('Christopher Nolan', '1970-07-30', 'UK'),
('Leonardo DiCaprio', '1974-11-11', 'USA'),
('Christian Bale',    '1974-01-30', 'UK');

-- Genres
INSERT INTO Genre (name) VALUES
('Action'), ('Sci-Fi'), ('Thriller'), ('Drama');

-- Skills
INSERT INTO Skill (name) VALUES
('Acting'), ('Directing'), ('Screenwriting'), ('Producing');

-- Roles
INSERT INTO Role (name) VALUES
('Actor'), ('Director'), ('Producer'), ('Writer');

-- Media for movies (Requirement 1)
INSERT INTO Media (movie_id, media_type, url) VALUES
(1, 'Video', 'http://media.com/inception_trailer.mp4'),
(1, 'Image', 'http://media.com/inception_poster.jpg'),
(2, 'Image', 'http://media.com/darkknight_poster.jpg');

-- Movie-Genre links (Requirement 2)
INSERT INTO Movie_Genre (movie_id, genre_id) VALUES
(1, 2), (1, 3),        -- Inception: Sci-Fi, Thriller
(2, 1), (2, 3),        -- Dark Knight: Action, Thriller
(3, 2), (3, 4);        -- Interstellar: Sci-Fi, Drama

-- Reviews (Requirement 3)
INSERT INTO Review (movie_id, user_id, review_text, score, created_on) VALUES
(1, 1, 'Mind-bending masterpiece.', 9.0, '2023-05-01'),
(1, 2, 'A bit confusing but great.', 8.0, '2023-05-03'),
(2, 1, 'Best superhero film ever.', 9.5, '2023-06-10');

-- Artist skills (Requirement 4)
INSERT INTO Artist_Skill (artist_id, skill_id) VALUES
(1, 2), (1, 3), (1, 4),   -- Nolan: Directing, Screenwriting, Producing
(2, 1),                    -- DiCaprio: Acting
(3, 1);                    -- Bale: Acting

-- Movie cast with multiple roles per artist in one film (Requirement 5)
-- Nolan is BOTH Director and Producer of Inception:
INSERT INTO Movie_Cast (movie_id, artist_id, role_id) VALUES
(1, 1, 2),   -- Inception - Nolan - Director
(1, 1, 3),   -- Inception - Nolan - Producer
(1, 2, 1),   -- Inception - DiCaprio - Actor
(2, 1, 2),   -- Dark Knight - Nolan - Director
(2, 3, 1);   -- Dark Knight - Bale - Actor

-- ============================================================
-- Verification queries (run these and screenshot the output)
-- ============================================================
SHOW TABLES;

-- Movies with their genres
SELECT m.title, g.name AS genre
FROM Movie m
JOIN Movie_Genre mg ON m.movie_id = mg.movie_id
JOIN Genre g        ON mg.genre_id = g.genre_id;

-- Reviews with movie title and reviewer
SELECT m.title, u.username, r.score, r.review_text
FROM Review r
JOIN Movie m ON r.movie_id = m.movie_id
JOIN User u  ON r.user_id  = u.user_id;

-- Artist appearing in multiple roles in one film
SELECT m.title, a.name AS artist, ro.name AS role
FROM Movie_Cast mc
JOIN Movie m  ON mc.movie_id  = m.movie_id
JOIN Artist a ON mc.artist_id = a.artist_id
JOIN Role ro  ON mc.role_id   = ro.role_id
ORDER BY m.title, a.name;
