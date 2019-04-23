DROP SCHEMA IF EXISTS classes CASCADE;
CREATE SCHEMA classes;

CREATE TABLE classes.taxon (
  curie text PRIMARY KEY,
  iri text UNIQUE,
  label text UNIQUE,
  id integer UNIQUE
);

INSERT INTO classes.taxon VALUES
('NCBITaxon:9606', 'http://purl.obolibrary.org/obo/NCBITaxon_9606',
 'Homo sapiens', 9606),
('NCBITaxon:10359', 'http://purl.obolibrary.org/obo/NCBITaxon_10359',
 'Human betaherpesvirus 5', 10359);

CREATE FUNCTION classes.taxon_curie(id numeric)
RETURNS text AS $$
  SELECT CASE WHEN id IS NOT NULL THEN CONCAT('NCBITaxon:', id) END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE TABLE classes.location (
  curie text PRIMARY KEY,
  iri text UNIQUE,
  label text UNIQUE
);
