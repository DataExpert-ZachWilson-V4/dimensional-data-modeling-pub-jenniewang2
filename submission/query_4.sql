INSERT INTO jennierxwang69225.actors_history_scd

WITH lagged as ( --creating a CTE to help us calculate later which actors have changed fields; this helper table looks for is the actor was active this year versus last year, as well as have a field to check quality class of last year
SELECT actor,
actor_id,
is_active,
LAG(is_active, 1) over (PARTITION by actor ORDER BY current_year) as is_active_last_year,
quality_class,
LAG(quality_class, 1) over (PARTITION by actor ORDER BY current_year) as quality_class_last_year,
current_year
from jennierxwang69225.actors
),

streak as (--this CTE uses the prior CTE to sum up the changes and have a method to track the years between changes
Select 
*,
SUM(CASE --we need a case statement to check for either change in activity or change in quality class 
    WHEN is_active <> is_active_last_year THEN 1 --checking for activity change
    WHEN quality_class <> quality_class_last_year THEN 1 --checking for quality class change
    ELSE 0 
  END) OVER (Partition by actor ORDER by current_year) as streak_identifier,
MAX(current_year) OVER() as this_year --getting the current year as this_year without hardcoding
from lagged
)

SELECT 
  actor,
  actor_id,
  MAX(quality_class) as quality_class,
  MAX(is_active) as is_active,
  MIN(current_year) as start_date,
  MAX(current_year) as end_date,
  this_year
from streak
GROUP BY actor, actor_id, streak_identifier, this_year --grouping by the streak identifier helps us realize the SCD as it will create additional entry rows when things change according to the logic in the "streak" table
