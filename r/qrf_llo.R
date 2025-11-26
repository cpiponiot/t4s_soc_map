library(quantregForest)

# ---- Function Definition ----
qrf_llo <- function(data, ycol, xcols, site,
                    nodesizes = c(5, 10, 15),
                    ntree = 500,
                    sampsize = NULL) {
  if (is.null(sampsize)) sampsize <- nrow(data)

  y <- data[[ycol]]
  x <- data[, xcols, drop = FALSE]

  sites <- unique(site)
  n <- nrow(data)

  # ---- Hyperparameter tuning ----
  cv_results <- data.frame(nodesize = nodesizes, RMSE = NA)

  for (ns in nodesizes) {
    preds <- numeric(n)

    for (s in sites) {
      train_idx <- which(site != s)
      test_idx <- which(site == s)

      qrf <- quantregForest(
        x = x[train_idx, , drop = FALSE],
        y = y[train_idx],
        nodesize = ns,
        ntree = ntree,
        sampsize = min(sampsize, length(train_idx))
      )

      preds[test_idx] <- predict(qrf, x[test_idx, , drop = FALSE], what = 0.5)
    }

    cv_results$RMSE[cv_results$nodesize == ns] <- sqrt(mean((y - preds)^2))
  }

  best_nodesize <- cv_results$nodesize[which.min(cv_results$RMSE)]
  message("Best nodesize chosen: ", best_nodesize)

  # ---- Train one model per fold ----
  models <- list()

  for (s in sites) {
    train_idx <- which(site != s)

    models[[as.character(s)]] <- quantregForest(
      x = x[train_idx, , drop = FALSE],
      y = y[train_idx],
      nodesize = best_nodesize,
      ntree = ntree,
      sampsize = min(sampsize, length(train_idx))
    )
  }

  # ---- Return object with predict method ----
  structure(list(
    models = models,
    xcols = xcols,
    best_nodesize = best_nodesize,
    cv_results = cv_results
  ), class = "qrf_llo")
}

# ---- Prediction Method ----
library(foreach)
library(doParallel)
predict.qrf_llo <- function(object, newdata,
                            aggregate = TRUE,
                            quantiles = c(0.1, 0.5, 0.9),
                            parallel = TRUE,
                            cores = max(1, parallel::detectCores() - 1)) {
  xnew <- newdata[, object$xcols, drop = FALSE]
  if (parallel) {
    cl <- makeCluster(cores)
    clusterExport(cl,
      varlist = c("xnew", "object", "quantiles"),
      envir = environment()
    )
    clusterEvalQ(cl, library(quantregForest))
    preds <- parLapply(
      cl, object$models,
      function(m) predict(m, xnew, what = quantiles)
    )
    stopCluster(cl)
  } else {
    # resample results for each prediction
    preds <- lapply(object$models, function(m) {
      predict(m, xnew, what = function(x) sample(x, 100, replace = TRUE))
    })
  }
  if (aggregate) {
    # 3D array: rows x quantiles x models
    preds_array <- simplify2array(preds)
    # Aggregate across models (quantiles)
    out <- t(apply(preds_array, 1, function(x) quantile(x, quantiles)))
    colnames(out) <- paste0("Q", quantiles * 100)
    return(out)
  } else {
    return(preds)
  }
}

# ---- Variable Importance Function ----
importance_qrf_llo <- function(object, type = 1) {
  # if type = 1: %IncMSE (default for regression)
  # if type = 2: IncNodePurity
  importances <- sapply(object$models, function(m) {
    m$importance[, type]
  })

  # importances is a matrix: variables x models
  avg_importance <- rowMeans(importances)

  # Return as data.frame sorted by importance
  data.frame(
    variable = names(avg_importance),
    importance = avg_importance,
    row.names = NULL
  )[order(-avg_importance), ]
}

# ---- Partial Dependence for qrf_llo ----
qrf_partial <- function(object, var, value, data, quantiles) {
  lapply(object$models, function(m) {
    predict(m, copy(data)[, (var) := value],
      what = function(x) sample(x, 20, replace = TRUE)
    )
  }) |>
    unlist() |>
    quantile(probs = quantiles) |>
    as.list()
}
