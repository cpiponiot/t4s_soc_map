library(pMEM)
library(magrittr)
objf <- function(par, m, fun, x, xx, y, yy, lb, ub) {
  ## Bound the parameter values within the lb -> ub intervals:
  par <- (ub - lb) * (1 + exp(-par))^(-1) + lb
  ## This step is necessary to prevent pitfalls during optimization.

  ## Calculate the SEF under the conditions requested
  if (fun %in% c("power", "hyperbolic")) {
    sef <- genSEF(x, m, genDWF(fun, range = par[1L], shape = par[2L]))
  } else {
    sef <- genSEF(x, m, genDWF(fun, range = par[1L]))
  }

  ## Calculate the minMSE model
  res <- getMinMSE(as.matrix(sef), y, predict(sef, xx), yy, FALSE)

  ## The objective criterion is the out of the sample mean squared error:
  res$mse
}

estimate_sef <- function(
  x, xx, y, yy, lower, upper,
  list_fun = c(
    "linear", "power", "hyperbolic", "spherical", "exponential",
    "Gaussian", "hole_effect"
  )
) {
  res <- list(optim = list()) ## A list to contain the results.

  ## This loop tries the seven DWF one by one, estimating 'dmax' (and, when
  ## necessary, 'shape') using simulated annealing.
  for (fun in list_fun) {
    res$optim[[fun]] <- optim(
      par = c(0, if (fun %in% c("power", "hyperbolic")) 0), fn = objf,
      method = "SANN", m = genDistMetric(), fun = fun,
      x = x, xx = xx, y = y, yy = yy,
      lb = c(lower[1], if (fun %in% c("power", "hyperbolic")) lower[2]),
      ub = c(upper[1], if (fun %in% c("power", "hyperbolic")) upper[2])
    )
  }

  ## Extract the minimum values from the list of optimization:
  res$bestval <- unlist(
    lapply(
      res$optim,
      function(x) x$value
    )
  )

  ## Find which DWF had the minimum objective criterion value:
  res$fun <- names(which.min(res$bestval))

  ## Back-transform the parameter values:
  res$par <- res %>%
    {
      .$optim[[.$fun]]$par #nolint
    } %>%
    {
      (upper - lower) * (1 + exp(-.))^(-1) + lower  #nolint
    }

  ## Calculate the SEF using the optimized DWF parameters:
  res$sef <- res %>%
    {
      genSEF(
        x = x,
        m = genDistMetric(),
        f = genDWF(.$fun, .$par[1L], if (length(.$par) > 1) .$par[2L]) #nolint
      )
    }

  ## Return the result list:
  res
}
