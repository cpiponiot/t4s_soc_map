ffs_select <- function(vars, data, select = NULL, response = "T_stock") {
  if (is.null(select)) select <- rep(TRUE, length(vars))
  if (length(vars) == 1) {
    return(TRUE)
  } else {
    ffsel <- data[, vars[select]] |>
      CAST::ffs(data[, response], metric = "Rsquared")
    # get list of predictor
    return(vars %in% ffsel$selectedvars)
  }
}
