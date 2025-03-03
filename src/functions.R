# List of functions used in climate averaging

.drop.col <- function(i, sp.df){
  sp.df@data <- sp.df@data[,i,drop=FALSE]
  return(sp.df)
}

.avg.climate <- function(shapefile, x){
  # average the climate variable across each object in the shapefile
  return(exact_extract(x = x, y = shapefile, "mean", progress=FALSE))
}

.avg.wrapper <- function(climate, region){
  # use parallelised code to run this for a list of temperature data
  return(do.call(cbind, mcMap(
    function(x) .avg.climate(shapefile=region, x),
    climate)))
}

.give.names <- function(output, rows, cols, rename=FALSE){
  # add names to the climate averaging output
  dimnames(output) <- list(rows, cols)
  if(rename)
    rownames(output) <- gsub(" ", "_", rownames(output))
  return(output)
}
