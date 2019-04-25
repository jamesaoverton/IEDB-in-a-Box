DROP SCHEMA IF EXISTS joined CASCADE;
CREATE SCHEMA joined;

-- Given a source schema name, source table name, a prefix, and a target view name
-- create a new view that duplicates the source
-- except that each column now starts with the prefix.
CREATE OR REPLACE FUNCTION joined.create_prefixed_view(
  target text, schema text, source text, prefix text, where_clause text DEFAULT ''
)
RETURNS void
AS $$
DECLARE
  result text;
BEGIN
  SELECT concat(
    'CREATE VIEW ', target,
    ' AS SELECT ', string_agg(x, ', '),
    ' FROM ', schema, '.', source),
    where_clause
  INTO result
  FROM (
    SELECT
      CASE
       WHEN column_name = prefix || '_id' THEN column_name
       ELSE format('%I AS %I_%I', column_name, prefix, column_name)
      END
      AS x
    FROM information_schema.columns
    WHERE table_schema=schema
      AND table_name=source
  ) t;
  EXECUTE result;
  RETURN;
END;
$$ LANGUAGE plpgsql STRICT;

SELECT joined.create_prefixed_view('joined.taxon_taxon', 'classes', 'taxon', 'taxon');
SELECT joined.create_prefixed_view('joined.location_location', 'classes', 'location', 'location');

CREATE VIEW joined.object AS
SELECT *
FROM core.object
LEFT JOIN joined.taxon_taxon USING (taxon_curie);

SELECT joined.create_prefixed_view('joined.object_object', 'joined', 'object', 'object');
SELECT joined.create_prefixed_view('joined.immunogen_object', 'joined', 'object', 'immunogen',
  'WHERE object_id IN (SELECT immunogen_object_id FROM core.process)');
-- immunogen_object
-- immunogen_containing_object
-- antigen_object
-- antigen_containing_object

CREATE VIEW joined.epitope AS
SELECT *
FROM core.epitope
LEFT JOIN joined.object_object USING (object_id);

SELECT joined.create_prefixed_view('joined.epitope_epitope', 'joined', 'epitope', 'epitope');

CREATE VIEW joined.host AS
SELECT *
FROM core.host
LEFT JOIN joined.taxon_taxon USING (taxon_curie)
LEFT JOIN joined.location_location USING (location_curie);

SELECT joined.create_prefixed_view('joined.host_host', 'joined', 'host', 'host');

CREATE VIEW joined.process AS
SELECT *
FROM core.process
LEFT JOIN joined.immunogen_object USING (immunogen_object_id);

SELECT joined.create_prefixed_view('joined.iv1_process', 'joined', 'process', 'iv1',
  'WHERE process_id IN (SELECT iv1_process_id FROM core.assay');
SELECT joined.create_prefixed_view('joined.ivt_process', 'joined', 'process', 'ivt',
  'WHERE process_id IN (SELECT ivt_process_id FROM core.assay');

CREATE VIEW joined.assay AS
SELECT *
FROM core.assay
LEFT JOIN joined.epitope_epitope USING (epitope_id)
LEFT JOIN joined.host_host USING (host_id)
LEFT JOIN joined.iv1_process USING (iv1_process_id)
LEFT JOIN joined.ivt_process USING (ivt_process_id);

-- SELECT * FROM joined.assay;


