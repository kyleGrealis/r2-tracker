box::use(
  dplyr[ filter, mutate, select ],
  httr2[ request, req_dry_run, req_headers, req_perform, resp_body_json ],
  jsonlite[ fromJSON, toJSON ],
  stringr[ str_remove ]
)

#' @export
data_pull <- function(name, type) {

  result <- request(sprintf("https://%s.kylegrealis.com/%s", name, type)) |> 
    req_headers("Content-Type" = "application/json") |> 
    req_perform() |> 
    resp_body_json() |> 
    toJSON(pretty = TRUE) |> 
    fromJSON() |> 
    # Strip the .parquet from the filename
    mutate(file = str_remove(file, "\\.parquet")) |> 
    select(-project)

  return(result)
}

# nascar <- request("https://nascar.kylegrealis.com/stats") |> 
#   req_headers("Content-Type" = "application/json") |> 
#   req_perform() |> 
#   resp_body_json() |> 
#   toJSON(pretty = TRUE) |> 
#   fromJSON()


# nhanes <- request("https://nhanes.kylegrealis.com/stats") |> 
#   req_headers("Content-Type" = "application/json") |> 
#   req_perform() |> 
#   resp_body_json() |> 
#   toJSON(pretty = TRUE) |> 
#   fromJSON()

# rbind(nascar, nhanes) |> 
#   mutate(
#     file = str_remove(file, "\\.parquet")
#   )
