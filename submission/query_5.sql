INSERT INTO jennierxwang69225.actors_history_scd

-- Select records from the previous year
WITH last_year AS (
    SELECT
        *
    FROM
        jennierxwang69225.actors_history_scd
),

-- Select records from the current year
current_year AS (
    SELECT 
        *
    FROM
        jennierxwang69225.actors
    WHERE
        current_year = (SELECT MAX(end_date) FROM jennierxwang69225.actors_history_scd) + 1 -- Use a subquery to get the latest year + 1
),

-- CTE to combine previous and current year data, identifying changes where they occur and using COALESCE to combine items
combined AS (
    SELECT
        COALESCE(ly.actor, cy.actor) AS actor,
        COALESCE(ly.actor_id, cy.actor_id) AS actor_id,
        COALESCE(ly.quality_class, cy.quality_class) AS quality_class,
        (SELECT MAX(end_date) FROM jennierxwang69225.actors_history_scd) + 1 AS latest_year,
        ly.is_active AS is_active_last_year,
        cy.is_active AS is_active_this_year,
        ly.quality_class AS quality_class_last_year,
        cy.quality_class AS quality_class_this_year,
        COALESCE(ly.start_date, cy.current_year) AS start_date,
        COALESCE(ly.end_date, cy.current_year) AS end_date,
        CASE
            WHEN ly.is_active <> cy.is_active THEN 1
            WHEN ly.quality_class <> cy.quality_class THEN 1
            WHEN ly.is_active = cy.is_active AND ly.quality_class = cy.quality_class THEN 0
        END AS did_change
    FROM
        last_year ly
    FULL OUTER JOIN
        current_year cy ON ly.actor_id = cy.actor_id AND (ly.end_date + 1) = cy.current_year
),

-- CTE to handle changes and create an array of changes
changes AS (
    SELECT 
        actor,
        actor_id,
        latest_year,
        CASE
            WHEN did_change = 0 THEN ARRAY[
                CAST(ROW(is_active_last_year, quality_class_last_year, start_date, end_date + 1) AS ROW(is_active BOOLEAN, quality_class VARCHAR, start_date INTEGER, end_date INTEGER))
            ]
            WHEN did_change = 1 THEN ARRAY[
                CAST(ROW(is_active_last_year, quality_class_last_year, start_date, end_date) AS ROW(is_active BOOLEAN, quality_class VARCHAR, start_date INTEGER, end_date INTEGER)), 
                CAST(ROW(is_active_this_year, quality_class_this_year, latest_year, latest_year) AS ROW(is_active BOOLEAN, quality_class VARCHAR, start_date INTEGER, end_date INTEGER))
            ]
            ELSE ARRAY[
                CAST(ROW(
                    COALESCE(is_active_last_year, is_active_this_year),
                    COALESCE(quality_class_last_year, quality_class_this_year),
                    start_date,
                    end_date) AS ROW(is_active BOOLEAN, quality_class VARCHAR, start_date INTEGER, end_date INTEGER))
            ]
        END AS change_array
    FROM 
        combined
)

-- Final selection and unnesting of the change array
SELECT
    actor,
    actor_id,
    arr.quality_class,
    arr.is_active,
    latest_year,
    arr.start_date,
    arr.end_date
FROM
    changes
CROSS JOIN UNNEST(change_array) AS arr
