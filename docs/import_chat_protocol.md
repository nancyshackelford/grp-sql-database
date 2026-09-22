# GRP import chat protocol

Version: 2026-09-22 (20260922 framework baseline)

This file is an instruction handoff for the assistant in a new project-import chat. The user may upload this file or point to its path in the repository. Read it before changing import code or data. GAZP10's completed stages and output folders remain the workflow baseline. `R/import_framework/20260922_framework/` is the active shared-code baseline for future imports; 0915 and 0918 remain pinned historical dependencies for GAZP10 and GAZP11. This protocol is not authority to add stages or outputs. The user's current instructions and reviewed project decisions take precedence.

## Objective and boundaries

Import one project through the same review-driven sequence established with GAZP10:

`source/harmonized review → preprocessing if needed → prepare → human review → build → human review → summarize → human review → commit dry run → explicit live-write authorization → commit and post-import audit`.

Do not collapse stages, silently approve your own scientific assumptions, or describe an intermediate partial output as a completed stage. Continue working within the current stage until its output contract is met or a real decision blocks it. Stop at each human-review gate. Reading Supabase for IDs, schema, or vocabularies is permitted during build; writing data or uploading artifacts is not permitted until the user explicitly authorizes the live commit.

The assistant performs the writing, staging, checks, and (once explicitly authorized) upload. The user supplies the project/source material, flags concerns, reviews consequential interpretations, and approves stage transitions. The user alone opens branches, stages or commits files, pushes, and merges; the assistant must not perform those Git operations unless the user explicitly changes that instruction. Preserve unrelated data and existing worktree changes.

## Start of a new import chat

1. Read this protocol, repository instructions, the current project's source and harmonized files, the GAZP10 scripts/output contracts, and the active `20260922_framework` functions. Do not assume the remembered chat summary is the authoritative version of the files.
2. Establish the project ID, branch/worktree, framework version, source files, harmonized workbook, paper(s), user-flagged issues, and current SQL/import status. Check whether the project already exists in SQL before allocating proposed IDs.
3. Inventory existing changes and outputs. Decide whether preprocessing is necessary. Do not reconstruct the whole project from raw data unless the user authorizes that scope. For each correction, distinguish a demonstrable harmonized-data error from a SQL representation decision.
4. Tell the user exactly which stage is active, its planned outputs, and its stopping point. Ask only for decisions that materially affect the data or SQL mapping.

## Placement of decisions

- **Preprocessing** corrects errors or reverses transformations in harmonized data. Examples: response back-transformation, measurement scales, survey-unit/year alignment, raw grazing labels, and source-supported treatment IDs. A treatment ID denotes one event but may have several action/detail rows. Run `audit_treatment_event_identity()` and review any conflicting date or context values within an ID here; multiple rows alone are not an error. Preserve an original-to-reprocessed audit. If raw records are missing, say so and identify any inference rather than claiming raw verification.
- **Prepare** converts approved harmonized content to stable, human-readable area and treatment-event keys; routes all action rows for an event to its one treatment ID; reconciles species; and audits every source row. It must not allocate SQL IDs or connect to SQL. The shared code rechecks event timing/context, rejects unreviewed conflicts, and uses checked many-to-one treatment lookups. Project-specific choices belong in the project script and review files; reusable rules belong in the single canonical import framework, but only after explicit review and approval as a forward-looking process change.
- **Build** consumes only approved prepare outputs, reads SQL state and vocabularies, allocates proposed IDs, creates SQL-shaped staging tables and crosswalks, and validates them. It must not write to SQL.
- **Summarize** records approval of the reviewed build, hashes all approved build files, checks live ID drift and project absence, and previews row counts, insertion order, provenance, artifacts, and transformations. It must not write to SQL.
- **Commit** first performs a dry run. A live transaction and artifact upload require a separate, explicit user authorization. Recheck hashes and live IDs immediately before writing; stop on drift. Produce receipts and post-import reconciliation. Never infer commit authorization from approval of a prior stage.

## Output-folder contract

Use `outputs/import_review/<PROJECT>/` with the four GAZP10 folders and their stage meanings. Compare filenames to GAZP10 at the *same stage*. Do not add a folder, a standard file, or a project-specific review file without showing the proposed deviation and obtaining user approval first. Do not move files merely to make counts match.

| Folder | Standard contents | Gate |
| --- | --- | --- |
| `prepare/` | GAZP10's nine files: `prepare_approval.csv`, `prepare_summary.csv`, `prepared_area.csv`, `prepared_area_treatment.csv`, `prepared_treatment.csv`, `prepared_vegresults.csv`, `project_manifest.csv`, `species_review.csv`, `vegresult_row_audit.csv` | User reviews mappings and row preservation before `prepare_approval.csv` is recorded. |
| `build/` | GAZP10's 36 `stg_*.csv` files (including headed zero-row tables), `staging_table_inventory.csv`, `build_summary.csv`, `build_validation_issues.csv`, two project crosswalks, and `build_approval.csv` after review | User reviews the complete SQL-shaped package before `build_approval.csv` is recorded. An earlier *partial* GAZP10 build was not the completed stage. |
| `summarize/` | `build_approval.csv`, `id_drift_check.csv`, `precommit_checks.csv`, `commit_preview.csv`, `import_batch_preview.csv`, `import_project_preview.csv`, `import_artifact_preview.csv`, `transformation_steps_preview.csv` | User reviews the commit plan. GAZP10's summarize script also wrote `build_approval.csv` into `build/` after build review. |
| `commit/` | GAZP10's nine files: `approved_build_hash_audit.csv`, `artifact_file_audit.csv`, `artifact_upload_receipt.csv`, `commit_dry_run.csv`, `database_insert_receipt.csv`, `documentation_schema_audit.csv`, `live_id_audit.csv`, `postcommit_row_audit.csv`, `target_schema_audit.csv` | Separate live-write approval; verify actual insertion and artifacts. |

Do not put `stg_*` tables in `prepare/`, and do not mistake their presence in `build/` for a SQL write. Do not create `build_approval.csv` before build review. Keep crosswalk copies in `crosswalk_tables/<DATABASE>/<PROJECT>/` only when the established project workflow calls for them, and verify they match the build copies.

## Spatial and treatment rules

1. A SQL `treatmentid` represents **one treatment event**, not one action/detail row. Seeding, bed preparation, and a nurse plant can have several rows under one event ID when implemented together. A later visit or application is a separate event ID, even when applied to the same area. The area–treatment table may link several event IDs to one treated area.
2. Link a treatment event only to the **child sampling area**, never to a parent block. A block-only source observation or proposed block link requires preprocessing review and an explicit child-area resolution before prepare; the shared framework must fail rather than fabricate a child or link its parent.
3. Area identity is a separate question from vegetation-result row identity. Multiple vegetation-result rows may legitimately refer to one area (for example, different species or times). Never create one area per result merely to satisfy a uniqueness check. Construct area keys from defensible source spatial identifiers and audit the number of observations per area.
4. Do not assume that same-looking IDs in different years are the same physical area. Establish the cross-year alignment from source evidence or keep years separate with an explicit note. Conversely, do not split confirmed repeat measurements merely because years differ.
5. Reconcile treatment links by event type and area level. At minimum report total areas, treated areas, parent links, child links, untreated/result areas, events per area, and any event linked to an unexpectedly broad area. Require zero parent links and an explicit event link for every vegetation-result area.
6. Keep grazing context or uncertainty in `notes` where the source only supports prose. Do not misuse `othertreatments` as a note field.
7. A passive/unseeded control has **no seed application method**. Do not stage `applicationmethod = none` as if it were an applied method. Preserve the source token for provenance, omit the false application-detail row, and use a neutral reference/control representation only when its meaning is supportable.
8. Do not infer herbicide, irrigation, grazing, or other events from a paper alone when the treated areas cannot be mapped to retained records. Record the published treatment and the mapping gap in project notes/review decisions. Do not force an unidentified passive group to stand for that treatment.

## Species, seed rates, and row-loss checks

- Match species against the **exact harmonized source code**, then map to the SQL `speciesid`. If SQL has aliases or numbered code variants sharing one ID, the project crosswalk must still contain one row per actual source code, with one accepted exact code. Enforce one-to-one crosswalk row cardinality; do not let a join on numeric `speciesid` alone multiply rows.
- Review species mappings for `vegresults`, `trtrates`, and site-invasive fields separately. Check controlled vocabularies and route seed pretreatment to `seeding_pretreatment`, not a generic treatment field.
- Reconcile source rows to prepared rows to staged rows, including year × treatment × species counts and response totals. Report all unmatched, duplicated, dropped, or fabricated rows. A zero-row staging table is allowed only when genuinely inapplicable, with a correct header.
- Validate key uniqueness, event-to-area coverage, parent relationships, foreign keys, lookup values, row counts, and exact source-to-SQL crosswalk cardinality. Do not mark an audit `pass` merely because its validator omitted an important domain rule; add the rule or surface a review decision.

## Approval and change control

- At every gate, give the user a short summary of what changed, important counts, unresolved decisions, and the exact review files. A `pass` in code is not human approval of an interpretation.
- Approval files bind the reviewed files to SHA-256 hashes. If an upstream file changes, invalidate downstream approval and regenerate affected stages. Do not quietly reuse an old approval hash or label a new change as previously reviewed.
- Stop **before implementing any departure** from the GAZP10 process, however small. Examples include a new stage, folder, file, output type, reusable rule, mapping convention, retry strategy, or protocol edit; this list is not exhaustive. Show the exact proposed change, reason, affected files/tables, and whether it changes approved data or live SQL; wait for explicit human review and approval of that change. Approval of a stage or live import is not blanket approval of later deviations. A failure, apparent bug fix, or seemingly harmless documentation change does not waive this gate. Report read-only findings while waiting.
- GAZP10 is a baseline, not a frozen or perfect process. After discussing a proposed import change, ask the user whether the approved decision applies only to this project or should become the standard for future imports. Project-specific approval does not authorize a protocol or framework change. If the user explicitly approves making it standard, update this protocol and the agreed reusable implementation, then show what changed. Never make process improvements silently.
- Maintain one canonical **active** import framework for standard functions and shared source code. Treat changes to it exactly like protocol changes: present the function-level diff and expected effects on future projects, obtain explicit approval that the change is process-wide, then create a reviewed, immutable version snapshot and designate it the new active baseline. Historical versions remain pinned for reproducibility, not as competing active standards. Do not overwrite, delete, or redirect a version already used by an import.
- Separate a bug fix within the approved design from a new scientific or SQL mapping decision. Even a bug fix that changes approved files or live state needs the appropriate review and authorization before execution. Do not turn a project-specific decision into a framework default without separate approval.
- The GAZP10 output package defines the default process, not every ecological fact. Record approved project-specific decisions in the existing project review outputs and notes, without creating a new document or folder by default.
- No live SQL write, artifact upload, or destructive cleanup without authorization appropriate to that action. Stop if the source-to-target mapping is materially unresolved.

## Commit safeguards within the GAZP10 stage

Keep the commit driver dry-run by default. After explicit live-write authorization, the assistant performs the live invocation; do not ask the user to edit a `FALSE`/`TRUE` switch. Recheck approved hashes, schema, IDs, and project absence before writing. Storage uploads and SQL are not atomic: if a live attempt fails, inspect receipts and live state, report the cause and any partial effects, and obtain review of any changed mapping or retry procedure **before** another write. Preserve GAZP10's commit outputs and independently verify live state after commit. Do not quietly alter approved build/summarize files or stored provenance after commit.

## Protocol change control

Do not update this protocol as an automatic end-of-import task. Propose the exact diff and its effect on the GAZP10 baseline, ask whether the decision is project-specific or a forward-looking process change, and obtain explicit human approval for the latter before editing. Keep project-specific findings in the existing project review outputs and task history unless the user approves a new artifact.

The `20260922_framework` source files are local and **not yet uploaded to Supabase**. After the next project import, remind the user to review their upload and provenance registration through `R/import_code/import_framework_import/`; do not silently upload them during that project's SQL commit.

### Protocol change log

| Date | Change | Reason |
| --- | --- | --- |
| 2026-09-21 | Initial version; clarified stage folders, plot-level treatment-link rule, exact-code species crosswalk, and review gates. | GAZP10 final workflow and GAZP11 review exposed ambiguity in intermediate versus final build outputs and parent-area treatment links. |
| 2026-09-22 | Removed the non-GAZP10 archive/closeout stage and automatic project closeout/protocol-update expectations; made GAZP10 stage folders, prior human review of any deviation, and user ownership of Git operations explicit. | User review found that GAZP11 closeout work had expanded the process without an equivalent GAZP10 step; the user confirmed that they handle branching, commits, pushes, and merges. |
| 2026-09-22 | Added an explicit choice between project-specific approval and a forward-looking process change. | The user expects the workflow to improve, but wants every evolution discussed and approved for its intended scope. |
| 2026-09-22 | Established one canonical active import framework, with framework changes subject to the same explicit process-wide approval as protocol changes. | The user wants standard functions shared across projects, not silent proliferation of versioned framework folders. |
| 2026-09-22 | Designated `20260922_framework` as the future baseline: several action rows may belong to one event ID; conflicting event dates/context are preprocessing review signals; passive `none` is not an application; treatment links are child-only; joins are checked many-to-one. | The user clarified event identity and approved these as process-wide rules while preserving historical framework versions for GAZP10/GAZP11. |
