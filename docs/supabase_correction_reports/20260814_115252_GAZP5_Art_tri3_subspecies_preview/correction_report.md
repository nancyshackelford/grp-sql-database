# GAZP5 Art_tri3 subspecies correction

Run timestamp: `20260814_115252`
Mode: `preview`
Database outcome: `PREVIEW_ONLY_NO_CHANGES`
Repository crosswalk outcome: `PREVIEW_ONLY_NO_CHANGES`
Assigned subspecies ID: `not assigned in preview`

Canonical taxon: Artemisia tridentata subsp. tridentata
Canonical species code: Art_tri_sub_tri
Source GAZP5 code: Art_tri3

The database transaction and local repository-file replacement are separate
operations because PostgreSQL and Git-tracked files cannot share one
transaction. The database is committed and verified first; the crosswalk is
then backed up, replaced, and re-verified on the local filesystem.

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
