library(meteo)

# ---- Function Definition ----
rfsi_llo <- function(data, formula_rfsi, site,
                     nodesizes = c(5, 10, 15),
                     ntree = 500) {
  sites <- unique(site)
  n <- nrow(data)
  y <- data.frame(data)[, as.character(formula_rfsi)[2]]

  # ---- Hyperparameter tuning ----
  cv_results <- data.frame(nodesize = nodesizes, RMSE = NA, R2 = NA)

  for (ns in nodesizes) {
    preds <- numeric(n)

    for (s in sites) {
      train_idx <- which(site != s)
      test_idx <- which(site == s)

      rsi <- rfsi(
        formula = formula_rfsi,
        data[train_idx, ],
        mtry = ns,
        num.trees = ntree
      ) |> suppressWarnings()

      preds[test_idx] <- pred.rfsi(rsi,
        data = data[train_idx, ],
        newdata = data[test_idx, ]
      )$pred
    }

    cv_results$RMSE[cv_results$nodesize == ns] <- sqrt(mean((y - preds)^2))
    cv_results$R2[cv_results$nodesize == ns] <- 1 - sum((y - preds)^2) /
      sum((y - mean(y))^2)
  }

  best_nodesize <- cv_results$nodesize[which.min(cv_results$RMSE)]
  message("Best nodesize chosen: ", best_nodesize)

  # ---- Train one model per fold ----
  models <- list()

  for (s in sites) {
    train_idx <- which(site != s)

    models[[as.character(s)]] <- rfsi(
      formula = formula_rfsi,
      data[train_idx, ],
      mtry = ns,
      num.trees = ntree
    )
  }

  # ---- Return object with predict method ----
  structure(list(
    models = models,
    formula = formula_rfsi,
    best_nodesize = best_nodesize,
    cv_results = cv_results
  ), class = "qrf_llo")
}
