# ecpe results -----------------------------------------------------------------
library(tidyverse)
library(MplusAutomation)

lcdm <- readModels(here("data-raw", "mplus", "lcdm.out"))

class_params <- lcdm$class_counts$modelEstimated |>
  as_tibble() |>
  select(parameter = class, true = proportion) |>
  mutate(parameter = paste0("nu[", parameter, "]"))

item_params <- lcdm$parameters$unstandardized |>
  as_tibble() |>
  filter(paramHeader == "New.Additional.Parameters") |>
  select(parameter = param, true = est) |>
  mutate(parameter = str_to_lower(parameter))

true_lcdm <- bind_rows(item_params, class_params)
write_rds(true_lcdm, "data-raw/raw-rds/true_lcdm.rds")

# lldcm results ----------------------------------------------------------------
library(lldcm)

ecpe_mod <- list(
  item1 = ~ a1 * a2,
  item2 = ~a2,
  item3 = ~ a1 * a3,
  item4 = ~a3,
  item5 = ~a3,
  item6 = ~a3,
  item7 = ~ a1 * a3,
  item8 = ~a2,
  item9 = ~a3,
  item10 = ~a1,
  item11 = ~ a1 * a3,
  item12 = ~ a1 * a3,
  item13 = ~a1,
  item14 = ~a1,
  item15 = ~a3,
  item16 = ~ a1 * a3,
  item17 = ~ a2 * a3,
  item18 = ~a3,
  item19 = ~a3,
  item20 = ~ a1 * a3,
  item21 = ~ a1 * a3,
  item22 = ~a3,
  item23 = ~a2,
  item24 = ~a2,
  item25 = ~a1,
  item26 = ~a3,
  item27 = ~a1,
  item28 = ~a3
)
ecpe_lldcm <- lldcm(
  as.matrix(dcmdata::ecpe_data[, -1]),
  3,
  ecpe_mod,
  maxit = 1000
)
ecpe_lldcm_reli <- reliab(ecpe_lldcm)

write_rds(ecpe_lldcm, "data-raw/raw-rds/ecpe_lldcm.rds")
write_rds(ecpe_lldcm_reli, "data-raw/raw-rds/ecpe_lldcm_reli.rds")
