vif_select <- function(vars, data, select = NULL, thres = 5) {
  if (is.null(select)) select <- rep(TRUE, length(vars))
  if (length(vars) == 1) {
    return(TRUE)
  } else {
    is_num <- sapply(vars, function(x) is.numeric(data[, x]))
    if (length(vars[select & is_num]) == 1) {
      return(TRUE)
    } else {
      vif_res <- data[, vars[select & is_num]] |> usdm::vifstep(th = thres)
      return(vars %in% c(vif_res@results$Variables, vars[select & !is_num]))
    }
  }
}
