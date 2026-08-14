# Supabase reconstruction audit

Snapshot: `2026-08-13`

This report compares Supabase-first reconstructed workbooks with the original harmonized GAZP Excel workbooks. Appended `supabase_*` audit columns are excluded from value comparison.

## Overall result

- Projects compared: 4
- Sheets compared: 29
- Exact normalized sheet matches: 8
- Missing reconstructed rows: 7297
- Unexpected reconstructed rows: 5998
- Key-aligned field mismatches: 7006

Normalization treats blank cells and literal `NA`/`N/A` as missing, compares text without case or redundant whitespace, and compares numeric values with a small floating-point tolerance.

## Sheet summary

| project_code | sheet | original_rows | reconstructed_rows | row_count_difference | familiar_columns | exact_normalized_rows | missing_rows | unexpected_rows | field_mismatches | exact_sheet_match |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| GAZP1 | study |    1 |    1 |     0 | 18 |    0 |    1 |    1 |    2 | FALSE |
| GAZP1 | site |    1 |    1 |     0 | 48 |    0 |    1 |    1 |   29 | FALSE |
| GAZP1 | treatments |  120 |  100 |   -20 | 15 |   80 |   40 |   20 |    0 | FALSE |
| GAZP1 | timepoints |   20 |   20 |     0 |  6 |    0 |   20 |   20 |   20 | FALSE |
| GAZP1 | cultivars |    0 |    0 |     0 |  6 |    0 |    0 |    0 |    0 | TRUE |
| GAZP1 | trtrates |  100 |  100 |     0 | 16 |    0 |  100 |  100 |    0 | FALSE |
| GAZP1 | refs |    0 |    0 |     0 | 14 |    0 |    0 |    0 |    0 | TRUE |
| GAZP1 | vegresults |  625 |  625 |     0 | 14 |  625 |    0 |    0 |    0 | TRUE |
| GAZP2 | study |    1 |    1 |     0 | 18 |    0 |    1 |    1 |    3 | FALSE |
| GAZP2 | site |    4 |    4 |     0 | 48 |    0 |    4 |    4 |  120 | FALSE |
| GAZP2 | treatments |  180 |  180 |     0 | 15 |   48 |  132 |  132 |  328 | FALSE |
| GAZP2 | timepoints |   72 |   72 |     0 |  6 |    0 |   72 |   72 |   72 | FALSE |
| GAZP2 | trtrates |  168 |  168 |     0 | 16 |    0 |  168 |  168 |    0 | FALSE |
| GAZP2 | refs |    0 |    0 |     0 | 14 |    0 |    0 |    0 |    0 | TRUE |
| GAZP2 | vegresults |  576 |  576 |     0 | 14 |  576 |    0 |    0 |    0 | TRUE |
| GAZP3 | study |    1 |    1 |     0 | 18 |    0 |    1 |    1 |    3 | FALSE |
| GAZP3 | site |    1 |    1 |     0 | 48 |    0 |    1 |    1 |   30 | FALSE |
| GAZP3 | treatments |    3 |    3 |     0 | 15 |    3 |    0 |    0 |    0 | TRUE |
| GAZP3 | timepoints |    9 |    9 |     0 |  6 |    0 |    9 |    9 |    9 | FALSE |
| GAZP3 | trtrates |    9 |    9 |     0 | 16 |    0 |    9 |    9 |    0 | FALSE |
| GAZP3 | refs |    0 |    0 |     0 | 14 |    0 |    0 |    0 |    0 | TRUE |
| GAZP3 | vegresults |   81 |   81 |     0 | 14 |   27 |   54 |   54 |    0 | FALSE |
| GAZP5 | study |    1 |    1 |     0 | 18 |    0 |    1 |    1 |    2 | FALSE |
| GAZP5 | site |  193 |  193 |     0 | 48 |    0 |  193 |  193 | 5597 | FALSE |
| GAZP5 | treatments | 1078 | 1150 |    72 | 15 |  283 |  795 |  867 |  790 | FALSE |
| GAZP5 | timepoints |  193 |  193 |     0 |  6 |  193 |    0 |    0 |    0 | TRUE |
| GAZP5 | trtrates | 4308 | 2957 | -1351 | 17 |    0 | 4308 | 2957 |    0 | FALSE |
| GAZP5 | refs |    1 |    1 |     0 | 14 |    0 |    1 |    1 |    1 | FALSE |
| GAZP5 | vegresults | 2772 | 2772 |     0 | 14 | 1386 | 1386 | 1386 |    0 | FALSE |

## Sheets requiring review

| project_code | sheet | original_rows | reconstructed_rows | exact_normalized_rows | missing_rows | unexpected_rows | field_mismatches |
| --- | --- | --- | --- | --- | --- | --- | --- |
| GAZP1 | study |    1 |    1 |    0 |    1 |    1 |    2 |
| GAZP1 | site |    1 |    1 |    0 |    1 |    1 |   29 |
| GAZP1 | treatments |  120 |  100 |   80 |   40 |   20 |    0 |
| GAZP1 | timepoints |   20 |   20 |    0 |   20 |   20 |   20 |
| GAZP1 | trtrates |  100 |  100 |    0 |  100 |  100 |    0 |
| GAZP2 | study |    1 |    1 |    0 |    1 |    1 |    3 |
| GAZP2 | site |    4 |    4 |    0 |    4 |    4 |  120 |
| GAZP2 | treatments |  180 |  180 |   48 |  132 |  132 |  328 |
| GAZP2 | timepoints |   72 |   72 |    0 |   72 |   72 |   72 |
| GAZP2 | trtrates |  168 |  168 |    0 |  168 |  168 |    0 |
| GAZP3 | study |    1 |    1 |    0 |    1 |    1 |    3 |
| GAZP3 | site |    1 |    1 |    0 |    1 |    1 |   30 |
| GAZP3 | timepoints |    9 |    9 |    0 |    9 |    9 |    9 |
| GAZP3 | trtrates |    9 |    9 |    0 |    9 |    9 |    0 |
| GAZP3 | vegresults |   81 |   81 |   27 |   54 |   54 |    0 |
| GAZP5 | study |    1 |    1 |    0 |    1 |    1 |    2 |
| GAZP5 | site |  193 |  193 |    0 |  193 |  193 | 5597 |
| GAZP5 | treatments | 1078 | 1150 |  283 |  795 |  867 |  790 |
| GAZP5 | trtrates | 4308 | 2957 |    0 | 4308 | 2957 |    0 |
| GAZP5 | refs |    1 |    1 |    0 |    1 |    1 |    1 |
| GAZP5 | vegresults | 2772 | 2772 | 1386 | 1386 | 1386 |    0 |

## Reconstruction and mapping statuses

| project_code | sheet | status_column | status_value | rows |
| --- | --- | --- | --- | --- |
| GAZP1 | site | reconstruction_status | partial; environmental fields not stored in Supabase |    1 |
| GAZP1 | study | reconstruction_status | reconstructed_from_supabase |    1 |
| GAZP1 | timepoints | reconstruction_status | reconstructed_from_veg_result_dates |   20 |
| GAZP1 | treatments | reconstruction_status | reverse_mapped_from_normalized_treatment_tables |  100 |
| GAZP1 | trtrates | cultivar_mapping_status | not_applicable_or_no_reverse_mapping |  100 |
| GAZP1 | trtrates | reconstruction_status | partial; treatment_type and trt_year not stored in seeding |  100 |
| GAZP1 | trtrates | species_mapping_status | unique_reverse_mapping |  100 |
| GAZP1 | vegresults | reconstruction_status | reverse_mapped_from_supabase |  625 |
| GAZP1 | vegresults | species_mapping_status | unique_reverse_mapping |  625 |
| GAZP2 | site | reconstruction_status | partial; environmental fields not stored in Supabase |    4 |
| GAZP2 | study | reconstruction_status | reconstructed_from_supabase |    1 |
| GAZP2 | timepoints | reconstruction_status | reconstructed_from_veg_result_dates |   72 |
| GAZP2 | treatments | reconstruction_status | reverse_mapped_from_normalized_treatment_tables |  180 |
| GAZP2 | trtrates | cultivar_mapping_status | not_applicable_or_no_reverse_mapping |  168 |
| GAZP2 | trtrates | reconstruction_status | partial; treatment_type and trt_year not stored in seeding |  168 |
| GAZP2 | trtrates | species_mapping_status | unique_reverse_mapping |   96 |
| GAZP2 | trtrates | species_mapping_status | ambiguous_multiple_legacy_codes |   72 |
| GAZP2 | vegresults | reconstruction_status | reverse_mapped_from_supabase |  576 |
| GAZP2 | vegresults | species_mapping_status | unique_reverse_mapping |  576 |
| GAZP3 | site | reconstruction_status | partial; environmental fields not stored in Supabase |    1 |
| GAZP3 | study | reconstruction_status | reconstructed_from_supabase |    1 |
| GAZP3 | timepoints | reconstruction_status | reconstructed_from_veg_result_dates |    9 |
| GAZP3 | treatments | reconstruction_status | reverse_mapped_from_normalized_treatment_tables |    3 |
| GAZP3 | trtrates | cultivar_mapping_status | not_applicable_or_no_reverse_mapping |    9 |
| GAZP3 | trtrates | reconstruction_status | partial; treatment_type and trt_year not stored in seeding |    9 |
| GAZP3 | trtrates | species_mapping_status | ambiguous_multiple_legacy_codes |    6 |
| GAZP3 | trtrates | species_mapping_status | unique_reverse_mapping |    3 |
| GAZP3 | vegresults | reconstruction_status | partial; species code ambiguous or absent |   54 |
| GAZP3 | vegresults | reconstruction_status | reverse_mapped_from_supabase |   27 |
| GAZP3 | vegresults | species_mapping_status | ambiguous_multiple_legacy_codes |   54 |
| GAZP3 | vegresults | species_mapping_status | unique_reverse_mapping |   27 |
| GAZP5 | refs | reconstruction_status | partial; full source author string not stored |    1 |
| GAZP5 | site | reconstruction_status | partial; environmental fields not stored in Supabase |  193 |
| GAZP5 | study | reconstruction_status | reconstructed_from_supabase |    1 |
| GAZP5 | timepoints | reconstruction_status | reconstructed_from_veg_result_dates |  193 |
| GAZP5 | treatments | reconstruction_status | reverse_mapped_from_normalized_treatment_tables | 1150 |
| GAZP5 | trtrates | cultivar_mapping_status | not_applicable_or_no_reverse_mapping | 2957 |
| GAZP5 | trtrates | reconstruction_status | partial; treatment_type and trt_year not stored in seeding | 2957 |
| GAZP5 | trtrates | species_mapping_status | unique_reverse_mapping | 2053 |
| GAZP5 | trtrates | species_mapping_status | ambiguous_multiple_legacy_codes |  902 |
| GAZP5 | trtrates | species_mapping_status | no_reverse_mapping |    2 |
| GAZP5 | vegresults | reconstruction_status | partial; species code ambiguous or absent | 1386 |
| GAZP5 | vegresults | reconstruction_status | reverse_mapped_from_supabase | 1386 |
| GAZP5 | vegresults | species_mapping_status | ambiguous_multiple_legacy_codes | 1386 |
| GAZP5 | vegresults | species_mapping_status | unique_reverse_mapping | 1386 |

Detailed CSV files in this folder retain the original and reconstructed rows/values for investigation.
