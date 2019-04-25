SELECT CONCAT(current_time, ' Loading core.object ...');

INSERT INTO core.object (
  object_id,
  object_type,
  reference_id,
  sequence,
  taxon_curie,
  molecule_id,
  source_molecule_id
)
SELECT DISTINCT
  ce.e_object_id,
  o.object_type,
  t.reference_id,
  o.mol1_seq,
  classes.taxon_curie(o.organism_id),
  o.mol1_source_id,
  o.mol2_source_id
FROM upstream.tcell t
INNER JOIN upstream.curated_epitope ce
  ON t.curated_epitope_id = ce.curated_epitope_id
INNER JOIN upstream.object o
  ON ce.e_object_id = o.object_id
UNION
SELECT DISTINCT
  t.iv1_imm_object_id,
  o.object_type,
  t.reference_id,
  o.mol1_seq,
  classes.taxon_curie(o.organism_id),
  o.mol1_source_id,
  o.mol2_source_id
FROM upstream.tcell t
INNER JOIN upstream.object o
  ON t.iv1_imm_object_id = o.object_id
UNION
SELECT DISTINCT
  t.ivt_imm_object_id,
  o.object_type,
  t.reference_id,
  o.mol1_seq,
  classes.taxon_curie(o.organism_id),
  o.mol1_source_id,
  o.mol2_source_id
FROM upstream.tcell t
INNER JOIN upstream.object o
  ON t.ivt_imm_object_id = o.object_id;


SELECT CONCAT(current_time, ' Loading core.epitope ...');

INSERT INTO core.epitope (
  epitope_id,
  reference_id,
  object_id,
  name,
  location,
  comments,
  evidence,
  region_start,
  region_end,
  region_domain_flag
)
SELECT DISTINCT
  ce.curated_epitope_id,
  ce.reference_id,
  o.object_id,
  ce.e_name,
  ce.e_location,
  ce.e_comments,
  ce.e_ev,
  ce.e_ref_start,
  ce.e_ref_end,
  ce.e_region_domain_flag
FROM upstream.curated_epitope ce
INNER JOIN core.object o ON o.object_id = ce.e_object_id;


SELECT CONCAT(current_time, ' Loading core.process ...');

INSERT INTO core.process (
  reference_id,
  process_type,
  adjuvants,
  route,
  dose_schedule,
  disease_curie,
  disease_stage,
  immunogen_evidence,
  immunogen_object_id,
  immunogen_containing_object_id
)
SELECT DISTINCT
  reference_id,
  iv1_process_type,
  iv1_adjuvants,
  iv1_route,
  iv1_dose_schedule,
  iv1_disease_id,
  iv1_disease_stage,
  iv1_imm_ev,
  iv1_imm_object_id,
  iv1_con_object_id
FROM tcell
WHERE iv1_process_type IS NOT null;


INSERT INTO core.process (
  reference_id,
  process_type,
  immunogen_evidence,
  immunogen_object_id,
  immunogen_containing_object_id
)
SELECT DISTINCT
  reference_id,
  ivt_process_type,
  ivt_imm_ev,
  ivt_imm_object_id,
  ivt_con_object_id
FROM tcell
WHERE ivt_process_type IS NOT null;


SELECT CONCAT(current_time, ' Loading core.host ...');

INSERT INTO core.host (
  sex,
  age,
  mhc_types_present,
  reference_id,
  taxon_curie,
  location_curie
)
SELECT DISTINCT
  h_sex,
  h_age,
  h_mhc_types_present,
  reference_id,
  classes.taxon_curie(h_organism_id),
  as_location
FROM upstream.tcell;


SELECT CONCAT(current_time, ' Creating temporary table tcell_host ...');

CREATE TEMP TABLE tcell_host AS
SELECT
  t.tcell_id,
  h.host_id
FROM upstream.tcell t
INNER JOIN core.host h
  -- If one variable is null in an '=' comparison, the comparison evaluates to null,
  -- so we need to explicitly check for this:
  ON (h.sex = t.h_sex
        OR (h.sex IS NULL AND t.h_sex IS NULL))
      AND (h.age = t.h_age
        OR (h.age IS NULL AND t.h_age IS NULL))
      AND (h.mhc_types_present = t.h_mhc_types_present
        OR (h.mhc_types_present IS NULL AND t.h_mhc_types_present IS NULL))
      AND (h.reference_id = t.reference_id
        OR (h.reference_id IS NULL AND t.reference_id IS NULL))
      AND (h.taxon_curie = classes.taxon_curie(t.h_organism_id)
        OR h.taxon_curie IS NULL AND classes.taxon_curie(t.h_organism_id) IS NULL)
      AND (h.location_curie = t.as_location
        OR (h.location_curie IS NULL AND t.as_location IS NULL))
ORDER BY t.tcell_id;


SELECT CONCAT(current_time, ' Adding immunogen_object_id columns to core.assay ...');

ALTER TABLE core.assay
  ADD COLUMN iv1_immunogen_object_id integer,
  ADD COLUMN ivt_immunogen_object_id integer;

CREATE INDEX iv1_immunogen_object_idx ON core.assay (iv1_immunogen_object_id);
CREATE INDEX ivt_immunogen_object_idx ON core.assay (ivt_immunogen_object_id);


SELECT CONCAT(current_time, ' Loading core.assay ...');

INSERT INTO core.assay (
  assay_type,
  supertype,
  location,
  comments,
  qualitative_measurement,
  quantitative_measurement,
  inequality,
  subjects_tested,
  subjects_responded,
  response_frequency,
  iv1_immunogen_epitope_relation,
  ivt_immunogen_epitope_relation,
  immunization_comments,
  antigen_conformation,
  reference_id,
  epitope_id,
  host_id,
  iv1_immunogen_object_id,
  ivt_immunogen_object_id
)
SELECT DISTINCT
  a.assay_type,
  'tcell',
  t.as_location,
  t.as_comments,
  -- qualitative measurement?
  null,
  -- quantitative measurement?
  null,
  t.as_inequality,
  t.as_num_subjects,
  t.as_num_responded,
  t.as_response_frequency,
  -- iv1_immunogen_epitope_relation?
  null,
  -- ivt_immunogen_epitope_relation?
  null,
  t.as_immunization_comments,
  t.ant_ref_name,
  t.reference_id,
  t.curated_epitope_id,
  th.host_id,
  t.iv1_imm_object_id,
  t.ivt_imm_object_id
FROM upstream.tcell t
INNER JOIN upstream.assay_type a ON t.as_type_id = a.assay_type_id
INNER JOIN tcell_host th ON th.tcell_id = t.tcell_id;


SELECT CONCAT(current_time, ' Adding process_id info to core.assay ...');

UPDATE core.assay a
SET iv1_process_id = (
  SELECT p.process_id
  FROM core.process p
  WHERE p.immunogen_object_id = a.iv1_immunogen_object_id
  LIMIT 1
);

UPDATE core.assay a
SET ivt_process_id = (
  SELECT p.process_id
  FROM core.process p
  WHERE p.immunogen_object_id = a.ivt_immunogen_object_id
  LIMIT 1
);


SELECT CONCAT(current_time, ' Dropping immunogen_object_id columns from core.assay ...');

ALTER TABLE core.assay
  DROP COLUMN iv1_immunogen_object_id,
  DROP COLUMN ivt_immunogen_object_id;


SELECT CONCAT(current_time, ' Done!');
