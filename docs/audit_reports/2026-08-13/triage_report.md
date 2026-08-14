# GAZP Supabase reconstruction audit: adjudicated status

Snapshot: `2026-08-13`

This report records the interpretation reached after exporting the existing GAZP data from Supabase, reconstructing project workbooks in the familiar harmonized Excel shape, comparing those workbooks with the original GAZP Excel files, reducing 7,006 field-level mismatches to repeated patterns, and manually reviewing the important patterns. The manually edited `triage_pattern_summary.csv` is the authoritative row-level adjudication record. This Markdown report explains the conclusions and the next work; it does not replace that CSV.

## What was done

1. A read-only, project-scoped raw snapshot was exported from Supabase. The snapshot retained the current Supabase identifiers and contained 39 project-related tables.
2. Repository crosswalks were used to reconstruct GAZP1, GAZP2, GAZP3, and GAZP5 into workbooks resembling the original harmonized Excel structure. Supabase identifiers and reconstruction-status fields were retained as additional columns.
3. The reconstructed workbooks were compared with the original harmonized workbooks using row counts, normalized comparisons, key-aligned field comparisons, and mapping-status summaries.
4. The 7,006 individual field mismatches were grouped into 168 repeated patterns so that causes could be reviewed rather than inspecting every cell separately.
5. The important patterns were manually adjudicated in `triage_pattern_summary.csv`.

## Confirmed database import errors

### Missing timepoint months

The `month` values from the original timepoint sheets were not uploaded for GAZP1, GAZP2, or GAZP3. The audit found 20 affected GAZP1 treatment/timepoint keys, 72 affected GAZP2 keys, and 9 affected GAZP3 keys. This was a genuine database omission.

The controlled correction was successfully applied on 2026-08-14 at 11:23:03. It populated and verified `month` on 1,282 `grp.veg_result` rows: 625 for GAZP1, 576 for GAZP2, and 81 for GAZP3. The original harmonized timepoint sheets contained no populated `day` values for these projects, so no days were available to backfill and no day values were changed. The transaction outcome was `COMMITTED_AND_VERIFIED`; row-level evidence and the run summary are retained in `docs/supabase_correction_reports/20260814_112303_GAZP1_GAZP3_timepoint_month_day_apply`. Snapshot `2026-08-13` predates this correction and remains the historical pre-correction audit snapshot.

### Species review and the `Art_tri3` taxonomy error

Several Supabase species IDs reverse-map to multiple legacy species codes. Each ambiguous code was reviewed against its project context. Only `Art_tri3` required correction in the central Supabase taxonomy: it represents *Artemisia tridentata* subsp. *tridentata* and had been incorrectly collapsed into the species-level *Artemisia tridentata* record.

That correction was completed and verified on 2026-08-14. Supabase created canonical `Art_tri_sub_tri` as species ID 7171, reassigned 462 GAZP5 vegetation-result rows and 177 normalized GAZP5 seeding rows, and moved the `Art_tri3` name mapping to the subspecies. The global repository species crosswalk was also updated and verified as `Art_tri3 -> 7171 -> Art_tri_sub_tri`. The database transaction evidence is retained in `docs/supabase_correction_reports/20260814_121118_GAZP5_Art_tri3_subspecies_apply`.

The other reviewed codes can remain mapped to their present accepted Supabase taxa. Some nevertheless preserve historical or regional taxonomic concepts that are useful provenance. Those concepts should not be added to the larger database, where taxonomy would become overly complicated and quickly outdated. Instead, they should be documented in project-specific species crosswalks that record what the source asserted, which accepted Supabase taxon was selected, and whether taxonomic detail changed or was collapsed during harmonization and import.

These crosswalks should normally be created by the import process, when both the source representation and the selected Supabase object are available. Export and reconstruction should consume them, not infer or generate them. Because the GAZP5 import predates this practice, its species crosswalk must be constructed retrospectively as a standalone post-import artifact using the original workbook, existing crosswalks, the Supabase snapshot, and the completed species review.

`Pse_rup` and `Pse_rup1` illustrate why project-level provenance is necessary. The source treated them as distinct concepts and included both in the same seed mix at different rates, even though both now map to the same accepted Supabase species ID. The Supabase records appear to retain the separate rates. The GAZP5 crosswalk can therefore recover the original identifier using a contextual reverse rule based on project, Supabase species ID, seeding rate, and rate units. The rule must be validated across all affected GAZP5 treatments; if the same compound values are ever non-unique, the treatment identifier must also be included as an exception key.

## Confirmed reconstruction/output changes

### USDA site classifications

USDA class, subclass, and subsubclass were not lost from Supabase. The relationship is stored for each site in `grp.site_classification` using a hierarchical classification identifier. The reconstruction must eventually join the appropriate classification vocabulary and return `USDA.class`, `USDA.subclass`, and `USDA.subsubclass` in the familiar site-sheet columns. Their absence from the first reconstructed workbooks is an output/reconstruction issue, not expected schema loss.

### Number of study timepoints

The first reconstruction counted unique `tsr` values across an entire project. That produced values such as 21 for GAZP5 even though the project had one monitoring point within each individual restoration treatment. The intended study-level value is:

> the maximum number of distinct monitoring points within any single treatment in the project.

The calculation may still be automated, but it must first count distinct monitoring points within each treatment and then take the maximum of those treatment-level counts. It must not count all distinct `tsr` values project-wide.

### Reverse species identifiers

Reconstructed `trtrates` and `vegresults` must eventually return meaningful source species identifiers. Reconstruction should first apply an applicable project-specific contextual crosswalk rule, then use an unambiguous project-specific species-ID mapping, and otherwise report unresolved ambiguity rather than guess. The `Art_tri3` database and global-crosswalk correction is complete. GAZP5 still requires the retrospective project-specific species crosswalk for historical concepts and contextual rules such as `Pse_rup` versus `Pse_rup1`. Supabase IDs and the crosswalk rule used should remain visible in reconstructed output for auditability.

## Reviewed differences that are not upload failures

### GAZP5 treatment-rate row reduction

The reduction from 4,308 original treatment-rate rows to 2,957 reconstructed rows is acceptable. Many seed-mix species were recorded twice in the original harmonized data because the same species and rate were applied at the same time by both broadcast seeding and drill/hand seeding. The normalized database represents one species/rate row while the treatment information retains the fact that the event used both application methods. This is normalization, not loss of the treatment event.

### GAZP5 treatment expansion

The additional reconstructed GAZP5 treatment rows are acceptable. They reflect the addition of `cover crop` as a structured treatment during import. Differences involving `cover crop` routed out of `othertreatments` are therefore expected normalization.

### GAZP1 treatment reduction

The missing 20 GAZP1 treatment rows correct an error in the original harmonized workbook. Grading appeared at both time 0 and time 1 in the original data, but that duplication was incorrect and was deliberately fixed during import. The reconstructed database result is preferred.

### `tsrfirst` and `tsrlast`

The reviewed differences in `tsrfirst` and `tsrlast` trace back to errors in the original harmonized project metadata. The refined values calculated from the uploaded data are accepted and should not be changed to reproduce the erroneous originals.

## Current conclusion

The audit did not reveal broad corruption of the uploaded GAZP data. Both confirmed database errors have now been corrected and verified: the missing GAZP1–3 timepoint months and the incorrect collapse of GAZP5 `Art_tri3`. The remaining reviewed taxonomic ambiguity is a provenance and reconstruction concern to be handled in project-specific crosswalks, not by expanding the central taxonomy. Other prominent differences were either reconstruction rules that need refinement or documented corrections/normalizations made during import.

## Agreed next steps

1. Design the folder and tracking system for controlled post-import database fixes and their review evidence.
2. Completed 2026-08-14: backfilled and verified the missing GAZP1–3 timepoint months on 1,282 vegetation-result rows.
3. Completed 2026-08-14: created and verified GAZP5 *Artemisia tridentata* subsp. *tridentata* as `Art_tri_sub_tri` / species ID 7171, reassigned the applicable records, and updated the global repository species crosswalk.
4. Build and validate the retrospective GAZP5 species crosswalk. It should preserve historical and regional source concepts and include the contextual reverse rule for `Pse_rup` and `Pse_rup1`.
5. For future projects, make creation of the project-specific species provenance crosswalk part of import; export/reconstruction should only consume it.
6. In a later audit iteration, revise reconstruction logic to restore USDA hierarchy columns, calculate study timepoints as the maximum number of distinct monitoring points within a single treatment, and apply the project species crosswalk.
7. After the project-specific GAZP5 species crosswalk is built, create a new raw snapshot and rerun reconstruction/comparison, preserving snapshot `2026-08-13` and its manually adjudicated triage CSV as historical evidence.

No database correction is performed by the current audit scripts.
