get_tene_coords <- function(plot, subplot, coord_init = c(-5.4892, 6.5317)) {
  library(sf)
  coords <- st_point(coord_init) |>
    st_sfc(crs = 4326) |>
    st_transform(2041)

  p <- as.numeric(plot)
  c <- as.numeric(subplot)
  # plot and subplot indices in x and y coordinates
  i <- ((p - 1) / 5 - floor((p - 1) / 5)) * 5 + 1
  j <- floor((p - 1) / 5) + 1
  a <- ((c - 1) / 2 - floor((c - 1) / 2)) * 2 + 1
  b <- floor((c - 1) / 2) + 1

  x <- 400 * (i - 0.5) + 100 * (a - 1.5)
  y <- 400 * (j - 0.5) + 100 * (b - 1.5)

  coords_all <- cbind(
    x = coords[[1]][1] + x,
    y = coords[[1]][2] - y
  ) |>
    st_multipoint() |>
    st_sfc(crs = 2041) |>
    st_transform(4326) |>
    st_coordinates()

  return(data.frame(lon = coords_all[, 1], lat = coords_all[, 2]))
}
