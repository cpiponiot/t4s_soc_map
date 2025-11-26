kfold <- function(data, var = "T_stock", outfold, fun_model, fun_pred) {
  obs_pred <- lapply(unique(data[, outfold]), function(i) {
    model <- data |>
      subset(get(outfold) != i) |>
      fun_model()
    pred_outfold <- fun_pred(
      model,
      subset(data, get(outfold) != i),
      subset(data, get(outfold) == i)
    )
    obs_outfold <- subset(data, get(outfold) == i)[, var]
    obs_infold_mean <- mean(subset(data, get(outfold) != i)[, var])
    return(cbind(obs_outfold, pred_outfold, obs_infold_mean)) #nolint
  })
  rmse <-
    lapply(obs_pred, function(x) sqrt(sum((x[, 1] - x[, 2])^2) / nrow(x))) |>
    unlist() |>
    mean()
  r2 <- lapply(obs_pred, function(x) {
    1 - sum((x[, 1] - x[, 2])^2) / sum((x[, 1] - x[, 3])^2)
  }) |>
    unlist() |>
    mean()
  return(c("rmse" = rmse, "r2" = r2))
}
