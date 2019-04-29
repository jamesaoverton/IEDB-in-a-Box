DROP SCHEMA IF EXISTS core CASCADE;
CREATE SCHEMA core;


CREATE TABLE core.object (
  object_id integer PRIMARY KEY,
  object_type text,
  reference_id integer NOT NULL,
  sequence text,
  taxon_curie text,
  molecule_id integer,
  source_molecule_id integer
);

CREATE INDEX reference_idx on core.object (reference_id);

CREATE TABLE core.epitope (
  epitope_id integer primary key,
  reference_id integer,
  object_id integer NOT NULL,
  name text,
  location text,
  comments text,
  evidence text,
  region_start integer,
  region_end integer,
  region_domain_flag text
);

CREATE TABLE core.host (
  host_id serial PRIMARY KEY,
  sex text,
  age text,
  mhc_types_present text,
  reference_id integer NOT NULL,
  taxon_curie text NOT NULL,
  location_curie text
);

CREATE UNIQUE INDEX host_idx ON core.host
(sex, age, mhc_types_present, reference_id, taxon_curie, location_curie);

CREATE TABLE core.process (
  process_id serial PRIMARY KEY,
  reference_id integer NOT NULL,
  process_type text,
  adjuvants text,
  route text,
  dose_schedule text,
  disease_curie integer,
  disease_stage text,
  immunogen_evidence text,
  immunogen_object_id integer,
  immunogen_containing_object_id integer
);

CREATE INDEX process_type_idx ON core.process (process_type);
CREATE INDEX immunogen_object_id_idx on core.process (immunogen_object_id);

CREATE TABLE core.assay (
  assay_id serial PRIMARY KEY,
  assay_type text,
  supertype text,
  location text,
  comments text,
  qualitative_measurement text,
  quantitative_measurement text,
  inequality text,
  subjects_tested integer,
  subjects_responded integer,
  response_frequency decimal,
  iv1_immunogen_epitope_relation text,
  ivt_immunogen_epitope_relation text,
  immunization_comments text,
  antigen_conformation text,
  reference_id integer NOT NULL,
  epitope_id integer NOT NULL,
  host_id integer NOT NULL,
  iv1_process_id integer,
  ivt_process_id integer
);
