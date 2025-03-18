#!/usr/bin/env Rscript

rlang::check_installed("httr2")
library(cli)
library(httr2)

out <- request("https://apps.ecmwf.int/status/status") %>% req_perform() %>% resp_body_string()
df <- jsonlite::fromJSON(out)$nodes
df <- data.frame(Title=df$node$Title, Last=df$node$`Last notification`, Status=df$node$Status)
df_entry <- subset(df, df$Title == "Data Stores")
final_vec <- as.character(df_entry[1,])

workcol <- col_yellow
if (tolower(final_vec[3]) == "ok") {
  workcol <- col_green
} else if (tolower(final_vec[3]) == "down") {
  workcol <- col_red
}

cli_h1("CDS Status")
cli_text("Service: {final_vec[1]}")
cli_text("Last Note: {final_vec[2]}")
cli_text(paste("Status:", workcol("{final_vec[3]}")))
cat("\n")
if (final_vec[3] == "Down") {
  quit(status=1)
}
