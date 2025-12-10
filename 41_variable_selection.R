## ----setup--------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
#| echo: false
#| results: 'hide'

library(tidyverse)
library(usdm)
library(CAST)
library(knitr)
library(randomForest)
library(caret)
list.files("r", pattern = "\\.R", full.names = TRUE) |> lapply(source)


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
data_all <- read.csv("data/cache/data_stocks.csv") %>%
  merge(read.csv("data/cache/climate_data.csv")) %>%
  merge(read.csv("data/cache/spectral_data.csv")) %>%
  merge(read.csv("data/cache/topo_data.csv")) %>%
  merge(read.csv("data/cache/thermal_data.csv")) %>%
  drop_na()


## -----------------------------------------------------------------------------------------------------------------------------
#| eval: false
formula_soc_all <- colnames(data_all) %>%
  setdiff(c("site", "plot", "lon", "lat", "T_stock")) %>%
  paste(collapse = " + ") %>%
  paste("T_stock ~", .) %>%
  as.formula()
training_index <- lapply(unique(data_all$site),
                         function(s) which(data_all$site != s))
rf_all <- train(
  form = formula_soc_all,
  data = data_all,
  method = "rf",
  metric = "RMSE",
  trControl = trainControl(method = "cv", index = training_index),
  ntree = 500, importance = TRUE
)
save(rf_all, file = "data/cache/models/rf_all.rda")


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
#| echo: false
load("data/cache/models/rf_all.rda")
cat(
  "RMSE:", mean(rf_all$resample$RMSE),
  "\nR²:", mean(rf_all$resample$Rsquared)
)


## -----------------------------------------------------------------------------------------------------------------------------
#| warning: false
# create groups
data_groups_vif <- data.frame(
  variable = setdiff(colnames(data_all),
                     c("site", "plot", "lon", "lat", "T_stock"))
) |> # vif selection by group, based on variables selected at previous stage
  mutate(vif = vif_select(variable, data_all))
list_vars <- data_groups_vif |>
  filter(vif) |>
  select(variable) |>
  unlist() |>
  paste(collapse = "; ")


## -----------------------------------------------------------------------------------------------------------------------------
#| eval: false
formula_soc_vif <- data_groups_vif %>%
  filter(vif) %>%
  select(variable) %>%
  t() %>%
  paste(collapse = " + ") %>%
  paste("T_stock ~", .) %>%
  as.formula()
training_index <- lapply(unique(data_all$site),
                         function(s) which(data_all$site != s))
rf_vif <- train(
  form = formula_soc_vif,
  data = data_all,
  method = "rf",
  metric = "RMSE",
  trControl = trainControl(method = "cv", index = training_index),
  ntree = 500, importance = TRUE
)
save(rf_vif, file = "data/cache/models/rf_vif.rda")


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
#| echo: false
load("data/cache/models/rf_vif.rda")
cat(
  "RMSE:", mean(rf_vif$resample$RMSE),
  "\nR²:", mean(rf_vif$resample$Rsquared)
)


## -----------------------------------------------------------------------------------------------------------------------------
#| warning: false
#| eval: false
# create groups
data_groups <- data.frame(
  variable = setdiff(colnames(data_all),
                     c("site", "plot", "lon", "lat", "T_stock"))
) |>
  mutate(group = ifelse(grepl("bio|LST", variable), "clim", "topo")) |>
  mutate(group = ifelse(grepl("_mean|NDVI", variable), "spectral", group)) |>
  group_by(group) |>
  # vif selection by group, based on variables selected at previous stage
  mutate(vif1 = vif_select(variable, data_all)) |>
  # ffs by group, based on variables selected at previous stage
  mutate(ffs1 = ffs_select(variable, data_all, vif1)) |>
  ungroup() |>
  # vif selection for all, based on variables selected at previous stage
  mutate(vif2 = vif_select(variable, data_all, ffs1)) |>
  # ffs for all, based on variables selected at previous stage
  mutate(ffs2 = ffs_select(variable, data_all, vif2))
write.csv(data_groups, file = "data/cache/var_selection.csv", row.names = FALSE)


## -----------------------------------------------------------------------------------------------------------------------------
#| warning: false
read.csv("data/cache/var_selection.csv") |>
  pivot_longer(cols = paste0(rep(c("vif", "ffs")), rep(1:2, each = 2))) |>
  group_by(group, name) |>
  summarise(vars = paste(variable[value], collapse = ", ")) |>
  pivot_wider(values_from = "vars") |>
  relocate(group, vif1, ffs1, vif2, ffs2) |>
  kable(col.names = c("Groups",
                      paste(rep(c("VIF", "FFS")),
                            rep(c("group", "all"), each = 2), sep = "_")))


## -----------------------------------------------------------------------------------------------------------------------------
#| eval: false
formula_soc_ffs <- read.csv("data/cache/var_selection.csv") %>%
  filter(ffs2) %>%
  select(variable) %>%
  t() %>%
  paste(collapse = " + ") %>%
  paste("T_stock ~", .) %>%
  as.formula()
training_index <- lapply(unique(data_all$site),
                         function(s) which(data_all$site != s))
rf_ffs <- train(
  form = formula_soc_ffs,
  data = data_all,
  method = "rf",
  metric = "RMSE",
  trControl = trainControl(method = "cv", index = training_index),
  ntree = 500, importance = TRUE
)
save(rf_ffs, file = "data/cache/models/rf_ffs.rda")


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
#| echo: false
load("data/cache/models/rf_ffs.rda")
cat(
  "RMSE:", mean(rf_ffs$resample$RMSE),
  "\nR²:", mean(rf_ffs$resample$Rsquared)
)


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
rf_models <- lapply(c("all", "vif", "ffs"), function(model) {
  load(paste0("data/cache/models/rf_", model, ".rda"))
  get(paste0("rf_", model))
})
names(rf_models) <- c("All Variables", "VIF selection", "VIF+FFS selection")
lapply(rf_models, function(md) md$results) %>%
  data.table::rbindlist(idcol = "model") %>%
  select(model, mtry, RMSE, Rsquared, MAE) %>%
  pivot_longer(
    cols = c(RMSE, Rsquared, MAE),
    names_to = "metric", values_to = "value"
  ) |>
  ggplot(aes(x = mtry, y = value, color = model)) +
  geom_line() +
  geom_point(size = 2) +
  facet_wrap(~metric, scales = "free_y") +
  labs(
    title = "Comparison of performance by mtry",
    x = "mtry (number of variables sampled)",
    y = "Metric value",
    color = "Model"
  ) +
  theme_minimal()


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
data_all <- read.csv("data/cache/data_stocks.csv") %>%
  merge(read.csv("data/cache/climate_data.csv")) %>%
  merge(read.csv("data/cache/spectral_data.csv")) %>%
  merge(read.csv("data/cache/topo_data.csv")) %>%
  merge(read.csv("data/cache/thermal_data.csv")) %>%
  merge(read.csv("data/cache/soil_data.csv")) %>%
  merge(read.csv("data/cache/bnedt_data.csv")) %>%
  drop_na()


## -----------------------------------------------------------------------------------------------------------------------------
#| eval: false
formula_soc_all <- colnames(data_all) %>%
  setdiff(c("site", "plot", "lon", "lat", "T_stock")) %>%
  paste(collapse = " + ") %>%
  paste("T_stock ~", .) %>%
  as.formula()
training_index <- lapply(unique(data_all$site),
                         function(s) which(data_all$site != s))
rf_all <- train(
  form = formula_soc_all,
  data = data_all,
  method = "rf",
  metric = "RMSE",
  trControl = trainControl(method = "cv", index = training_index),
  ntree = 500, importance = TRUE
)
save(rf_all, file = "data/cache/models/rf_all_extended.rda")


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
#| echo: false
load("data/cache/models/rf_all_extended.rda")
cat(
  "RMSE:", mean(rf_all$resample$RMSE),
  "\nR²:", mean(rf_all$resample$Rsquared)
)


## -----------------------------------------------------------------------------------------------------------------------------
#| warning: false
# create groups
data_groups_vif <- data.frame(
  variable = setdiff(colnames(data_all),
                     c("site", "plot", "lon", "lat", "T_stock"))
) |> # vif selection by group, based on variables selected at previous stage
  mutate(vif = vif_select(variable, data_all))
list_vars <- data_groups_vif |>
  filter(vif) |>
  select(variable) |>
  unlist() |>
  paste(collapse = "; ")


## -----------------------------------------------------------------------------------------------------------------------------
#| eval: false
formula_soc_vif <- data_groups_vif %>%
  filter(vif) %>%
  select(variable) %>%
  t() %>%
  paste(collapse = " + ") %>%
  paste("T_stock ~", .) %>%
  as.formula()
training_index <- lapply(unique(data_all$site),
                         function(s) which(data_all$site != s))
rf_vif <- train(
  form = formula_soc_vif,
  data = data_all,
  method = "rf",
  metric = "RMSE",
  trControl = trainControl(method = "cv", index = training_index),
  ntree = 500, importance = TRUE
)
save(rf_vif, file = "data/cache/models/rf_vif_extended.rda")


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
#| echo: false
load("data/cache/models/rf_vif_extended.rda")
cat(
  "RMSE:", mean(rf_vif$resample$RMSE),
  "\nR²:", mean(rf_vif$resample$Rsquared)
)


## -----------------------------------------------------------------------------------------------------------------------------
#| warning: false
#| eval: false
# # create groups
data_groups <- data.frame(
  variable = setdiff(colnames(data_all),
                     c("site", "plot", "lon", "lat", "T_stock"))
) |>
  mutate(group = ifelse(grepl("bio|LST", variable), "clim", variable)) |>
  mutate(group = ifelse(grepl("_mean|NDVI", variable), "spectral", group)) |>
  mutate(group = ifelse(grepl("elev|slope|aspect|twi", variable),
                        "topo", group)) |>
  group_by(group) |>
  # vif selection by group, based on variables selected at previous stage
  mutate(vif1 = vif_select(variable, data_all)) |>
  # ffs by group, based on variables selected at previous stage
  mutate(ffs1 = ffs_select(variable, data_all, vif1)) |>
  ungroup() |>
  # vif selection for all, based on variables selected at previous stage
  mutate(vif2 = vif_select(variable, data_all, ffs1)) |>
  # ffs for all, based on variables selected at previous stage
  mutate(ffs2 = ffs_select(variable, data_all, vif2))
write.csv(data_groups, file = "data/cache/var_selection_extended.csv",
          row.names = FALSE)


## -----------------------------------------------------------------------------------------------------------------------------
#| warning: false
read.csv("data/cache/var_selection_extended.csv") |>
  pivot_longer(cols = paste0(rep(c("vif", "ffs")), rep(1:2, each = 2))) |>
  group_by(group, name) |>
  summarise(vars = paste(variable[value], collapse = ", ")) |>
  pivot_wider(values_from = "vars") |>
  relocate(group, vif1, ffs1, vif2, ffs2) |>
  kable(col.names = c("Groups",
                      paste(rep(c("VIF", "FFS")),
                            rep(c("group", "all"), each = 2), sep = "_")))


## -----------------------------------------------------------------------------------------------------------------------------
#| eval: false
formula_soc_ffs <- read.csv("data/cache/var_selection_extended.csv") %>%
  filter(ffs2) %>%
  select(variable) %>%
  t() %>%
  paste(collapse = " + ") %>%
  paste("T_stock ~", .) %>%
  as.formula()
training_index <- lapply(unique(data_all$site),
                         function(s) which(data_all$site != s))
rf_ffs <- train(
  form = formula_soc_ffs,
  data = data_all,
  method = "rf",
  metric = "RMSE",
  trControl = trainControl(method = "cv", index = training_index),
  ntree = 500, importance = TRUE
)
save(rf_ffs, file = "data/cache/models/rf_ffs_extended.rda")


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
#| echo: false
load("data/cache/models/rf_ffs_extended.rda")
cat(
  "RMSE:", mean(rf_ffs$resample$RMSE),
  "\nR²:", mean(rf_ffs$resample$Rsquared)
)


## -----------------------------------------------------------------------------------------------------------------------------
#| message: false
#| warning: false
rf_models <- lapply(c("all", "vif", "ffs"), function(model) {
  load(paste0("data/cache/models/rf_", model, "_extended.rda"))
  get(paste0("rf_", model))
})
names(rf_models) <- c("All Variables", "VIF selection", "VIF+FFS selection")
lapply(rf_models, function(md) md$results) %>%
  data.table::rbindlist(idcol = "model") %>%
  select(model, mtry, RMSE, Rsquared, MAE) %>%
  pivot_longer(
    cols = c(RMSE, Rsquared, MAE),
    names_to = "metric", values_to = "value"
  ) |>
  ggplot(aes(x = mtry, y = value, color = model)) +
  geom_line() +
  geom_point(size = 2) +
  facet_wrap(~metric, scales = "free_y") +
  labs(
    title = "Comparison of performance by mtry",
    x = "mtry (number of variables sampled)",
    y = "Metric value",
    color = "Model"
  ) +
  theme_minimal()

