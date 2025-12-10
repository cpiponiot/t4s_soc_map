library(terra)

# path <- "data/download/SRTM/"
# init_file <- "SRTM_V3_stack_30m_CI"
path <- "data/download/BNEDT/"
init_file <- "BNEDT_OCS_2020.tif"

# make tiles
paste0(path, init_file, ".tif") |> rast() |> 
  makeTiles(12e3, filename = paste0(path, "tile_.tif"))

# group tiles
list.files(path, pattern = "tile", full.names = TRUE) |> 
  vrt(paste0(path, init_file, "_vrt.tif"))

# write final raster
r <- rast(paste0(path, init_file, "_vrt.tif"))
names(r) <- names(rast(paste0(path, "tile_1.tif")))
writeRaster(r, paste0(path, init_file, ".tif"))

# remove temp files
list.files(path, "tile|vrt", full.names = TRUE) |> 
  file.remove()


