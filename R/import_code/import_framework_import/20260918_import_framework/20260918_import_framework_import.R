## Archive the exact GAZP11 prepare-framework dependency in Supabase Storage.
## This upload does not designate 20260918 as the future active baseline.

library(httr2)
library(readr)
library(digest)

framework_version <- "20260918_framework"
framework_dir <- file.path("R", "import_framework", framework_version)
framework_files <- c(
  "prepare_functions.R", "build_functions.R", "import_registry.r",
  "import_helper_functions.r", "sp_crosswalk.csv"
)
local_files <- file.path(framework_dir, framework_files)
if (any(!file.exists(local_files))) {
  stop("Framework files missing: ",
       paste(local_files[!file.exists(local_files)], collapse = ", "), call. = FALSE)
}

source(file.path(framework_dir, "import_helper_functions.r"))
read_secret_bom_safe <- function(path) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  if (length(bytes) >= 3L && identical(as.integer(bytes[1:3]), c(239L, 187L, 191L)))
    bytes <- bytes[-(1:3)]
  while (length(bytes) > 0L && tail(as.integer(bytes), 1L) %in% c(10L, 13L))
    bytes <- head(bytes, -1L)
  rawToChar(bytes)
}

supabase_url <- "https://rudybfqutvodkakgctpo.supabase.co"
service_role <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/skey.csv"
)
bucket <- "import_framework"
receipt_path <- file.path(
  "R", "import_code", "import_framework_import", "20260918_import_framework",
  "20260918_framework_upload_receipt.csv"
)
receipt <- if (file.exists(receipt_path))
  read_csv(receipt_path, show_col_types = FALSE) else
  tibble::tibble(file_name = character(), destination_path = character(),
                 sha256 = character(), bytes = double(), status_code = integer())

paths <- paste(framework_version, framework_files, sep = "/")
hashes <- toupper(vapply(local_files, digest, character(1), algo = "sha256", file = TRUE))
sizes <- as.numeric(file.info(local_files)$size)
if (anyDuplicated(receipt$destination_path) ||
    any(!receipt$destination_path %in% paths) ||
    any(receipt$status_code != 200L))
  stop("Existing upload receipt is inconsistent; stop before writing.", call. = FALSE)

for (i in seq_along(local_files)) {
  prior <- match(paths[[i]], receipt$destination_path)
  if (!is.na(prior)) {
    if (receipt$sha256[[prior]] != hashes[[i]] || receipt$bytes[[prior]] != sizes[[i]])
      stop("A previously uploaded local file changed: ", framework_files[[i]],
           call. = FALSE)
    next
  }
  result <- upload_to_supabase(
    local_file = local_files[[i]], bucket = bucket,
    destination_path = paths[[i]], supabase_url = supabase_url,
    service_key = service_role, upsert = FALSE
  )
  receipt <- dplyr::bind_rows(receipt, tibble::tibble(
    file_name = framework_files[[i]], destination_path = result$destination_path,
    sha256 = hashes[[i]], bytes = sizes[[i]],
    status_code = as.integer(result$status_code)
  ))
  write_csv(receipt, receipt_path)
}

if (nrow(receipt) != length(framework_files))
  stop("Upload receipt does not cover all framework files.", call. = FALSE)

# Read each object back and compare bytes, not only HTTP upload status.
for (i in seq_along(paths)) {
  response <- request(paste0(supabase_url, "/storage/v1/object/authenticated/",
                             bucket, "/", paths[[i]])) |>
    req_headers(apikey = service_role,
                Authorization = paste("Bearer", service_role)) |>
    req_error(is_error = function(resp) FALSE) |>
    req_perform()
  if (resp_status(response) != 200L ||
      toupper(digest(resp_body_raw(response), algo = "sha256", serialize = FALSE)) != hashes[[i]])
    stop("Uploaded object failed read-back verification: ", paths[[i]], call. = FALSE)
}

message("Uploaded and read-back verified ", length(paths),
        " framework files; receipt: ", receipt_path)
