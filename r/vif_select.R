vif_select <- function(vars, data, select = NULL, thres = 5) {
  if (is.null(select)) select <- rep(TRUE, length(vars))
  if (length(vars) == 1) {
    return(TRUE)
  } else {
    vif_res <- data[, vars[select]] |> vifstep(th = thres)
    return(vars %in% vif_res@results$Variables)
  }
}