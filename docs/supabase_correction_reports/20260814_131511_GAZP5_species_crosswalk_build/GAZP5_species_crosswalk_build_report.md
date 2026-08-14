# GAZP5 species crosswalk build

Run datestamp: `20260814_131511`
Generated at UTC: `2026-08-14T20:15:11Z`
Outcome: `LOCAL_BUILD_WRITTEN_AND_VERIFIED`

Output: `crosswalk_tables/GAZP/GAZP5/GAZP5_species_crosswalk.csv`
Historical evidence: `data/harmonized/GRP_archives/species_long_traits3-2021-October-26.xlsx`
Historical artifact SHA-256: `fa9b1fa0242949fc93440f7b3431a9b2d6b7c9b9dfb7eac183ea9f2d5b4188cb`
Output SHA-256: `6164b8b6bdceb6e720044526214b8716da73b5ac14b41fe1e9da70d39d2a3148`

No Supabase database, Storage, import-documentation, or
project_object_crosswalk changes were made by this script.
The three mix_unknown trtrates rows were explicitly validated and excluded
as unknown-composition seed-mix placeholders, not species identifiers.

## Summary

# A tibble: 1 × 9
  project_code source_species_codes crosswalk_rows default_rules
  <chr>                       <int>          <int>         <int>
1 GAZP5                          56             67            54
# ℹ 5 more variables: contextual_rules <int>, human_reviewed_codes <int>,
#   automated_flagged_codes <int>, output_sha256 <chr>, generated_at_utc <chr>
