optimise_split <- function(x, size_max = 40e6, niter = 1000) {
  if (size_max < max(x)) {
    stop("size_max is not enough (there are larger single files).")
  }

  iters <- lapply(seq_len(niter), function(n) {
    seq_files <- sample(seq_len(length(x)))
    seq_folders <- c()
    for (i in seq_len(length(seq_files))) {
      if (length(seq_files) > 0) {
        seq_folders[[i]] <- seq_files[cumsum(x[seq_files]) <= size_max]
        seq_files <- seq_files[cumsum(x[seq_files]) > size_max]
      }
    }
    return(seq_folders) # nolint
  })
  min_n_folders <- lapply(iters, length) |>
    unlist() |>
    min()

  iters_min <- iters[lapply(iters, length) == min_n_folders]

  size_max <- lapply(iters_min, function(y) {
    max(unlist(lapply(y, function(i) sum(x[i]))))
  })
  return(iters_min[[which.min(size_max)]])
}
