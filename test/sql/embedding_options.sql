SET enable_seqscan = off;

\qecho
\set ON_ERROR_STOP on


CREATE TABLE t (val vector(3));
-- todo::

DROP TABLE t;
