## Upload the versioned GRP import-framework bundle to Supabase Storage.

library(httr2)

supabase_url <- "https://rudybfqutvodkakgctpo.supabase.co"
service_role <- readLines(
  "C:\\Users\\nshack\\OneDrive - University of Victoria\\Documents\\R\\GRP\\skey.csv",
  warn = FALSE
)

bucket <- "import_framework"
framework_version <- "20260903_framework"
framework_dir <- file.path("R", "import_framework", framework_version)

framework_files <- c(
  "20260612_import_registry.r",
  "20260620_import_helper_functions.r",
  "20260825_species_crosswalk_creation.R",
  "20260605_sp_crosswalk.csv",
  "cultivar_crosswalk.csv"
)

local_files <- file.path(framework_dir, framework_files)
missing_files <- local_files[!file.exists(local_files)]

if (length(missing_files) > 0) {
  stop(
    "The following framework files are missing: ",
    paste(missing_files, collapse = ", ")
  )
}

auth_headers <- c(
  apikey = service_role,
  Authorization = paste("Bearer", service_role)
)

# Create the private bucket if it does not already exist. Listing buckets is
# more reliable here than checking a single missing bucket because Supabase can
# wrap a 404 NoSuchBucket response in a different HTTP status.
bucket_response <- request(
  paste0(supabase_url, "/storage/v1/bucket")
) |>
  req_headers(!!!auth_headers) |>
  req_error(is_error = function(resp) FALSE) |>
  req_perform()

if (resp_status(bucket_response) >= 400) {
  stop(
    "Could not list the Supabase Storage buckets: ",
    resp_body_string(bucket_response)
  )
}

existing_buckets <- resp_body_json(bucket_response, simplifyVector = TRUE)
bucket_exists <- is.data.frame(existing_buckets) &&
  "id" %in% names(existing_buckets) &&
  bucket %in% existing_buckets$id

if (!bucket_exists) {
  create_response <- request(
    paste0(supabase_url, "/storage/v1/bucket")
  ) |>
    req_method("POST") |>
    req_headers(!!!auth_headers) |>
    req_body_json(list(
      id = bucket,
      name = bucket,
      public = FALSE
    )) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()

  if (resp_status(create_response) >= 400) {
    stop(
      "Could not create the Supabase Storage bucket: ",
      resp_body_string(create_response)
    )
  }
}

# Use the versioned helper being archived so upload behaviour stays aligned
# with project-import scripts.
source(file.path(framework_dir, "20260620_import_helper_functions.r"))

upload_results <- lapply(seq_along(local_files), function(i) {
  upload_to_supabase(
    local_file = local_files[[i]],
    bucket = bucket,
    destination_path = gsub(
      "\\\\",
      "/",
      file.path(framework_version, framework_files[[i]])
    ),
    supabase_url = supabase_url,
    service_key = service_role,
    upsert = TRUE
  )
})

upload_summary <- do.call(
  rbind,
  lapply(upload_results, function(result) {
    data.frame(
      local_file = result$local_file,
      bucket = result$bucket,
      destination_path = result$destination_path,
      status_code = result$status_code
    )
  })
)

print(upload_summary)
