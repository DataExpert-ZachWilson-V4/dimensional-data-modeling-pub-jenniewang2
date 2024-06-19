INSERT INTO jennierxwang69225.actors

WITH last_year as(
SELECT * from jennierxwang69225.actors --we can select * in this case because this is the final table format
WHERE current_year = 2007
),

current_year as(
SELECT --we will use a groupby and ARRAY_AGG to format this CTE to be a similar to the table we are inserting into to simplify later code
actor,
actor_id,
ARRAY_AGG(ROW(
  film,
  votes,
  rating,
  film_id
)) as films, --aliasing the same as the original table/CTE
year as current_year,
avg(rating) as avg_rating
from bootcamp.actor_films
WHERE year = 2008
GROUP by actor, actor_id, year --these groupbys help us get to an actor x year granularity to mirror the table we want to insert into)
)

SELECT 
  COALESCE(ly.actor, cy.actor) as actor, --using COALESCE to handle possible NULLS in actor names from the full outer join
  COALESCE(ly.actor_id, cy.actor_id) as actor_id, --using COALESCE to handle possible NULLS in actor_ids from the full outer join
  CASE --Case statement needs to handle three major possibilities
    WHEN ly.films IS NULL THEN cy.films --this is when the actor first appears, and thus ly.films is null;  in this case we use cy.films
    WHEN cy.films IS NULL THEN ly.films --this is when the actor does not have anything for this year; in this case we use ly.films
    WHEN cy.films is NOT NULL and ly.films IS NOT null --this is when the actor has films for both current and last year; we concat
      THEN cy.films || ly.films
    END as films,
  CASE --Case statement to handle quality class and bucketing
    WHEN avg_rating > 8 THEN 'star'
    WHEN avg_rating > 7 AND avg_rating <= 8 THEN 'good'
    WHEN avg_rating > 6 AND avg_rating <= 7 THEN 'average'
    WHEN avg_rating <= 6 THEN 'bad'
  END as quality_class,
  CASE --Case statement to look for current year activity
    WHEN cy.films IS NOT NULL THEN TRUE ELSE FALSE  
  END as is_active,
  COALESCE(cy.current_year, ly.current_year + 1) as current_year -- COALESCING to deal with nulls like before
  from last_year as ly
  FULL OUTER JOIN current_year as cy
  on cy.actor = ly.actor
