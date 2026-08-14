# GAZP5 `Art_tri3` correction plan

Status: completed and verified on 2026-08-14. Supabase assigned species ID 7171.

The database transaction created `Art_tri_sub_tri`, reassigned 462 GAZP5
vegetation-result rows and 177 GAZP5 seeding rows, moved the `Art_tri3` name
record, and passed post-update verification. The repository crosswalk replacement
was initially blocked because the CSV was open; after it was closed, the mapping
was completed and verified as `Art_tri3 -> 7171 -> Art_tri_sub_tri` without
rerunning or modifying Supabase.

## Problem

During the GAZP5 import, source code `Art_tri3` was mapped to Supabase species ID 484, the species-level *Artemisia tridentata* record. The source code actually represents *Artemisia tridentata* subsp. *tridentata*, which is a distinct accepted taxonomic record in the database model.

The audited pre-correction state contains 462 GAZP5 vegetation-result rows and 177 normalized GAZP5 seeding rows using species ID 484. The original workbook contains 462 `vegresults` rows and 252 `trtrates` rows for `Art_tri3`; the treatment-rate reduction is the previously reviewed normalization of duplicate application-method rows.

## Approved correction

The canonical Supabase species code is `Art_tri_sub_tri`. The species record will use genus `Artemisia`, species `tridentata`, subtype `subspecies`, subtype name `tridentata`, and lifeform `shrub`. Supabase will generate its numeric species ID.

The correction has three required targets:

1. Create or validate the canonical subspecies in `grp.species`, and move the `Art_tri3` entry in `grp.species_names` to that record with the name *Artemisia tridentata* subsp. *tridentata*.
2. Reassign only GAZP5 `grp.veg_result` and `grp.seeding` records currently using species ID 484 to the generated subspecies ID.
3. Update `crosswalk_tables/20260605_sp_crosswalk.csv` so `Art_tri3` maps to the generated species ID and `Art_tri_sub_tri`.

The mappings for `Art_tri` and `Art_tri2` remain attached to species ID 484. Records outside GAZP5 are not reassigned.

## Safety and evidence

The script `R/supabase_correction_code/02_correct_GAZP5_Art_tri3_subspecies.R` defaults to preview mode. Apply mode locks and revalidates all targets, performs the database changes in one transaction, verifies the resulting counts and names, and commits only after successful verification.

The Git-tracked CSV cannot participate in the PostgreSQL transaction. Therefore, the verified database transaction is committed first. The script then copies the pre-correction crosswalk into the run’s correction-report folder, writes and verifies a temporary corrected CSV, replaces the repository crosswalk, and verifies the final mapping. The correction report records the generated species ID and the outcome of both operations.

No historical or regional taxonomic notes are added to the central database. Those remain part of the later project-specific GAZP5 species crosswalk.
