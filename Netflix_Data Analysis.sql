DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);

SELECT * FROM netflix;

-- (1.) Count the number of Movies vs TV Shows

SELECT type, COUNT(*)
	FROM netflix
GROUP BY type;

-- (2.) Find the most common rating for movies and TV shows
SELECT
	type,
	rating
FROM(
	SELECT 
		type,
		rating,
		COUNT(*) AS rating_count,
		RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC)
	FROM
		netflix
	GROUP BY type, rating) t1
WHERE rank = 1;

-- (3.) List all movies released in a specific year (e.g., 2020)

SELECT * FROM netflix
WHERE 
	type = 'Movie'
	AND
	release_year =  2020;

-- (4.) Find the top 5 countries with the most content on Netflix

/* SELECT country, COUNT(show_id) AS content
	FROM netflix
WHERE country IS NOT NULL
GROUP BY country
ORDER BY COUNT(show_id) DESC
LIMIT 5; */ 
-- Here we do not use this query because 'country' column contains multiple country in single column.

SELECT
	UNNEST(STRING_TO_ARRAY(country, ',')) AS new_country,
	COUNT(show_id) AS Total_content
FROM
	netflix
GROUP BY
	new_country
ORDER BY
	Total_content DESC
LIMIT 5;

-- (5.) Identify the longest movie

SELECT
	title,
	duration
FROM
	netflix
WHERE type = 'Movie'
	AND
	duration = (SELECT MAX(duration) FROM netflix);

-- All these movies have same or maximum duration that is 99 min

-- (6.) Find Content added in last 5 Years

SELECT * FROM netflix
WHERE
	TO_DATE(date_added,'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 Years';

-- (7.) Find all the movies/TV shows by director 'Rajiv Chilaka'!

SELECT 
	* FROM netflix
WHERE 
	director ILIKE '%Rajiv Chilaka%';

-- Alternative --
SELECT * FROM
	(SELECT *,
		TRIM(UNNEST(STRING_TO_ARRAY(director, ','))) AS director_name
	FROM 
		netflix) t1
WHERE director_name = 'Rajiv Chilaka';

-- (8.) List all TV shows with more than 5 Seasons

SELECT *
FROM netflix
WHERE 
	TYPE = 'TV Show'
	AND
	SPLIT_PART(duration, ' ', 1)::INT > 5
--	CAST(SPLIT_PART(duration, ' ',1) AS INT) > 5

-- (9.) Count the number of content items in each genre

SELECT
	UNNEST(STRING_TO_ARRAY(listed_in, ',')) AS Genre,
	COUNT(Show_id) AS Total_Contents
FROM
	netflix
GROUP BY 
	Genre
ORDER BY
	genre;

-- (10.) Find each year and the average numbers of content release by India on netflix. 
-- return top 5 year with highest avg content release !

SELECT
    EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) AS releasing_year,
    COUNT(show_id) AS content,
    ROUND(
        (COUNT(*)::numeric / (SELECT COUNT(*) FROM netflix WHERE country = 'India')::numeric) * 100,
        2
    ) AS avg_content_per_year
FROM netflix
WHERE country = 'India'
GROUP BY releasing_year
ORDER BY releasing_year;

-- (11.) List all the movies that are documentaries.

SELECT * FROM netflix
WHERE listed_in ILIKE '%documentaries%';

-- (12.) Find all content without a director

SELECT * FROM netflix
WHERE director IS NULL;

-- (13.) Find how many movies actor 'Salman Khan' appeared in last 10 years

SELECT *
FROM netflix
WHERE type = 'Movie'
  AND casts LIKE '%Salman Khan%'
  AND release_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10;

-- (14.) Find the top 10 Actors who have appeared in the highest number of movies in India.

SELECT
	UNNEST(STRING_TO_ARRAY(casts, ',')) AS actors,
	COUNT(show_id) AS number_of_movies
FROM netflix
WHERE type = 'Movie' AND country = 'India'
	GROUP BY actors
	ORDER BY number_of_movies DESC
	LIMIT 10;

/* (15.) Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
the description field. Label content containing these keywords as 'Bad' and all other 
content as 'Good'. Count how many items fall into each category. */

SELECT 
	category,
	type,
	COUNT(*) AS content_count
	FROM(
		SELECT *,
			CASE
				WHEN description ILIKE '%Kill%' OR description ILIKE '%violence%' THEN 'Bad'
				ELSE 'Good'
			END AS category
		FROM netflix)t
	GROUP BY category, type
	ORDER BY content_count;