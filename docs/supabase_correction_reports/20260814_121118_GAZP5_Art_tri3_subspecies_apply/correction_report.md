# GAZP5 Art_tri3 subspecies correction

Run timestamp: `20260814_121118`
Mode: `apply`
Database outcome: `DATABASE_COMMITTED_AND_VERIFIED`
Repository crosswalk outcome: `UPDATED_AND_VERIFIED_AFTER_FILE_UNLOCK`
Assigned subspecies ID: `7171`

Canonical taxon: Artemisia tridentata subsp. tridentata
Canonical species code: Art_tri_sub_tri
Source GAZP5 code: Art_tri3

The database transaction and local repository-file replacement are separate
operations because PostgreSQL and Git-tracked files cannot share one
transaction. The database is committed and verified first; the crosswalk is
then backed up, replaced, and re-verified on the local filesystem.

The initial automatic replacement was blocked because the active crosswalk CSV
was open in another application. Supabase had already committed and verified
successfully. After the CSV was closed, the repository mapping was completed as
`Art_tri3 -> 7171 -> Art_tri_sub_tri` and independently verified. Supabase was
not rerun or modified during this follow-up.

## Summary

# A tibble: 1 × 14
  project_code source_species_code old_speciesid canonical_species_code
  <chr>        <chr>                       <int> <chr>                 
1 GAZP5        Art_tri3                      484 Art_tri_sub_tri       
# ℹ 10 more variables: canonical_speciesid_before_apply <int>,
#   source_veg_rows <int>, source_trtrate_rows <int>,
#   supabase_veg_rows_to_reassign <int>,
#   supabase_seeding_rows_to_reassign <int>, crosswalk_current_speciesid <int>,
#   crosswalk_current_species_code <chr>, assigned_speciesid <int>,
#   database_outcome <chr>, repository_crosswalk_outcome <chr>
