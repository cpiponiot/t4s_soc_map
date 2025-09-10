ffs_select <- function(vars, data, select = NULL, response = "T_stock") {
  if (is.null(select)) select <- rep(TRUE, length(vars))
  if (length(vars) == 1) {
    return(TRUE)
  } else {
    ffsel <-  data[, vars[select]] |> 
      ffs(data[, response], metric = "Rsquared") #, importance = TRUE, seed = 1000
    # get list of predictor
    return(vars %in% ffsel$selectedvars)
  }
}