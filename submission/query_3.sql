Create table jennierxwang69225.actors_history_scd(
actor VARCHAR,
actor_id VARCHAR,
quality_class VARCHAR,
is_active BOOLEAN,
start_date INTEGER,
end_date INTEGER,
current_year INTEGER
)
with
(
format = 'PARQUET',
partitioning = ARRAY['current_year']
)
