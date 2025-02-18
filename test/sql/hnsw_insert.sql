\ir test_helpers/small_world.sql
\ir test_helpers/sift.sql

CREATE INDEX ON small_world USING hnsw (vector);
CREATE INDEX ON sift_base1k USING hnsw (v);

SET enable_seqscan = off;

INSERT INTO small_world (id, vector) VALUES ('xxx', '[0,0,0]');
INSERT INTO small_world (id, vector) VALUES ('x11', '[0,0,110]');
INSERT INTO small_world (id, vector) VALUES 
('000', '[0,0,0]'),
('001', '[0,0,1]'),
('010', '[0,1,0]'),
('011', '[0,1,1]'),
('100', '[1,0,0]'),
('101', '[1,0,1]'),
('110', '[1,1,0]'),
('111', '[1,1,1]');

SELECT * FROM (
    SELECT id, ROUND(vector_l2sq_dist(vector, '[0,1,0]')::numeric, 2) as dist
    FROM small_world
    ORDER BY vector <-> '[0,1,0]' LIMIT 7
) v ORDER BY v.dist, v.id;

INSERT INTO small_world (id, vector) VALUES 
('000', '[0,0,0]'),
('001', '[0,0,1]'),
('010', '[0,1,0]'),
('011', '[0,1,1]'),
('100', '[1,0,0]'),
('101', '[1,0,1]'),
('110', '[1,1,0]'),
('111', '[1,1,1]');

SELECT * FROM (
    SELECT id, ROUND(vector_l2sq_dist(vector, '[0,1,0]')::numeric, 2) as dist
    FROM small_world
    ORDER BY vector <-> '[0,1,0]' LIMIT 7
) v ORDER BY v.dist, v.id;

SELECT v as v42 FROM sift_base1k WHERE id = 42 \gset 

-- no index scan
BEGIN;
DROP INDEX IF EXISTS sift_base1k_hnsw_idx;
EXPLAIN SELECT id, ROUND(vector_l2sq_dist(v, :'v42')::numeric, 2) FROM sift_base1k ORDER BY v <-> :'v42' LIMIT 10;
SELECT id, ROUND(vector_l2sq_dist(v, :'v42')::numeric, 2) FROM sift_base1k ORDER BY v <-> :'v42' LIMIT 10;
ROLLBACK;

-- index scan
EXPLAIN SELECT id, ROUND(vector_l2sq_dist(v, :'v42')::numeric, 2) FROM sift_base1k ORDER BY v <-> :'v42' LIMIT 10;
SELECT id, ROUND(vector_l2sq_dist(v, :'v42')::numeric, 2) FROM sift_base1k ORDER BY v <-> :'v42' LIMIT 10;
-- todo:: craft an SQL query to compare the results of the two above so I do not have to do it manually


-- another insert test
CREATE TABLE new_small_world as SELECT * from small_world;
CREATE INDEX ON new_small_world USING hnsw (vector);

INSERT INTO new_small_world (id, vector) VALUES
('000', '[0,0,0]'),
('001', '[0,0,1]'),
('010', '[0,1,0]'),
('011', '[0,1,1]'),
('100', '[1,0,0]'),
('101', '[1,0,1]'),
('110', '[1,1,0]'),
('111', '[1,1,1]');
-- index scan
SELECT '[0,0,0]'::vector as v42  \gset
EXPLAIN SELECT id, ROUND(vector_l2sq_dist(vector, :'v42')::numeric, 2) FROM new_small_world ORDER BY vector <-> :'v42' LIMIT 10;
SELECT id, ROUND(vector_l2sq_dist(vector, :'v42')::numeric, 2) FROM new_small_world ORDER BY vector <-> :'v42' LIMIT 10;

SELECT count(*) from sift_base1k;
SELECT * from ldb_get_indexes('sift_base1k');
INSERT INTO sift_base1k(v)
SELECT v FROM sift_base1k WHERE id <= 444 AND v IS NOT NULL;
SELECT count(*) from sift_base1k;
SELECT * from ldb_get_indexes('sift_base1k');

-- make sure NULL inserts into the index are handled correctly
INSERT INTO small_world (id, vector) VALUES ('xxx', NULL);
\set ON_ERROR_STOP off
INSERT INTO small_world (id, vector) VALUES ('xxx', '[1,1,1,1]');
\set ON_ERROR_STOP on
