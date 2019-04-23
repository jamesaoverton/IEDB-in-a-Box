DROP SCHEMA IF EXISTS core CASCADE;
CREATE SCHEMA core;


CREATE TABLE core.object (
  object_id serial PRIMARY KEY,
  epitope_object_id integer NOT NULL,
  iv1_imm_object_id integer,
  ivt_imm_object_id integer,
  object_type text,
  reference_id integer NOT NULL,
  sequence text,
  organism_id text,
  molecule_id integer,
  source_molecule_id integer
);

CREATE INDEX epitope_object_idx on core.object (epitope_object_id);
CREATE INDEX iv1_imm_object_idx on core.object (iv1_imm_object_id);
CREATE INDEX ivt_imm_object_idx on core.object (ivt_imm_object_id);


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

CREATE TABLE core.tcell_host (
  tcell_id integer PRIMARY KEY,
  host_id integer
);

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
  reference_id integer, -- NOT NULL,
  epitope_id integer, -- NOT NULL,
  host_id integer, -- NOT NULL,
  iv1_immunogen_object_id integer,
  ivt_immunogen_object_id integer,
  iv1_process_id integer, -- NOT NULL,
  ivt_process_id integer -- NOT NULL
);

CREATE INDEX iv1_immunogen_object_idx ON core.assay (iv1_immunogen_object_id);
CREATE INDEX ivt_immunogen_object_idx ON core.assay (ivt_immunogen_object_id);
