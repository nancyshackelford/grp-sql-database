## Upload the versioned 20260915 GRP import-framework bundle to Supabase Storage.

library(httr2)
library(readr)

framework_version <- "20260915_framework"
framework_dir <- file.path("R", "import_framework", framework_version)
framework_files <- c(
  "prepare_functions.R",
  "build_functions.R",
  "import_registry.r",
  "import_helper_functions.r",
  "sp_crosswalk.csv"
)
local_files <- file.path(framework_dir, framework_files)
missing_files <- local_files[!file.exists(local_files)]
if(length(missing_files)>0L) {
  stop("Missing framework files: ",paste(missing_files,collapse=", "),call.=FALSE)
}

# Source the exact upload helper that is being archived with this bundle.
source(file.path(framework_dir,"import_helper_functions.r"))

read_secret_bom_safe <- function(path) {
  bytes <- readBin(path,"raw",n=file.info(path)$size)
  if(length(bytes)>=3L && identical(as.integer(bytes[1:3]),c(239L,187L,191L))) {
    bytes <- bytes[-(1:3)]
  }
  while(length(bytes)>0L && tail(as.integer(bytes),1L) %in% c(10L,13L)) {
    bytes <- head(bytes,-1L)
  }
  rawToChar(bytes)
}

supabase_url <- "https://rudybfqutvodkakgctpo.supabase.co"
service_role <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/skey.csv"
)
bucket <- "import_framework"
auth_headers <- c(apikey=service_role,Authorization=paste("Bearer",service_role))

# Confirm the private framework bucket exists; create it only if absent.
bucket_response <- request(paste0(supabase_url,"/storage/v1/bucket")) |>
  req_headers(!!!auth_headers) |>
  req_error(is_error=function(resp) FALSE) |>
  req_perform()
if(resp_status(bucket_response)>=400L) {
  stop("Could not list Supabase Storage buckets: ",resp_body_string(bucket_response),call.=FALSE)
}
existing_buckets <- resp_body_json(bucket_response,simplifyVector=TRUE)
bucket_exists <- is.data.frame(existing_buckets) &&
  "id" %in% names(existing_buckets) && bucket %in% existing_buckets$id
if(!bucket_exists) {
  create_response <- request(paste0(supabase_url,"/storage/v1/bucket")) |>
    req_method("POST") |>
    req_headers(!!!auth_headers) |>
    req_body_json(list(id=bucket,name=bucket,public=FALSE)) |>
    req_error(is_error=function(resp) FALSE) |>
    req_perform()
  if(resp_status(create_response)>=400L) {
    stop("Could not create the framework bucket: ",resp_body_string(create_response),call.=FALSE)
  }
}

upload_results <- lapply(seq_along(local_files),function(i) {
  upload_to_supabase(
    local_file=local_files[[i]],bucket=bucket,
    destination_path=paste(framework_version,framework_files[[i]],sep="/"),
    supabase_url=supabase_url,service_key=service_role,upsert=TRUE
  )
})
upload_summary <- do.call(rbind,lapply(upload_results,function(result) {
  data.frame(
    local_file=result$local_file,bucket=result$bucket,
    destination_path=result$destination_path,status_code=result$status_code
  )
}))
receipt_path <- file.path(
  "R","import_code","import_framework_import","20260915_import_framework",
  "20260915_framework_upload_receipt.csv"
)
write_csv(upload_summary,receipt_path)
print(upload_summary)
message("Uploaded ",nrow(upload_summary)," framework files; receipt: ",receipt_path)

