# GAZP1-3 timepoint month/day correction

Run timestamp: `20260814_112303`
Mode: `apply`
Outcome: `COMMITTED_AND_VERIFIED`

The authoritative values came from the original harmonized timepoints sheets.
Source treatmentid + tsr was mapped to areaid with the repository project crosswalks.
Only missing grp.veg_result month/day values were eligible for update.
Existing conflicting values cause the script to stop without committing.

## Summary

# A tibble: 3 × 9
  project_code source_timepoint_keys supabase_rows month_rows_to_update
  <chr>                        <int>         <int>                <int>
1 GAZP1                           20           625                  625
2 GAZP2                           72           576                  576
3 GAZP3                            9            81                   81
# ℹ 5 more variables: month_rows_already_correct <int>,
#   month_source_missing <int>, day_rows_to_update <int>,
#   day_rows_already_correct <int>, day_source_missing <int>

The transaction was committed only after live read-back verification.
