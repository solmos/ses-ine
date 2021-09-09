library(tidyverse)
library(sf)
library(tmap)
library(googledrive)

## INE data ===============================================================

income_raw <- read_csv2("data/income_raw.csv", na = c("."))
gini_raw <- read_csv2("data/gini_raw.csv", na = c("."))

income_stats <- c(
  "Renta neta media por persona",
  "Renta neta media por hogar"
)
income <- income_raw %>%
  setNames(c("location", "stat_label", "year", "value")) %>%
  filter(
    str_detect(location, "sección"),
    stat_label %in% income_stats
  ) %>%
  mutate(
    cusec = str_extract(location, "^[0-9]+")
  ) %>%
  pivot_wider(names_from = stat_label, values_from = value) %>%
  rename(
    net_income_avg = "Renta neta media por persona",
    net_income_avg_household = "Renta neta media por hogar"
  ) %>%
  select(-location)

gini <- gini_raw %>%
  setNames(c("location", "stat_label", "year", "value")) %>%
  filter(
    str_detect(location, "sección")
  ) %>%
  mutate(
    cusec = str_extract(location, "^[0-9]+")
  ) %>%
  pivot_wider(names_from = stat_label, values_from = value) %>%
  rename(
    gini = "Índice de Gini",
    p80_p20 = "Distribución de la renta P80/P20"
  ) %>%
  select(-location)

## Original maps ==========================================================

spain_map <- read_sf("data/maps/ine/SECC_CE_20180101.shp")
cat_map <- spain_map %>%
  filter(NCA == "Cataluña")
bcn_map <- cat_map %>%
  filter(NMUN == "Barcelona")

## Merged data ==========================================================

ses_cat_sf <- cat_map %>%
  left_join(income, by = c(CUSEC = "cusec")) %>%
  left_join(gini, by = c(CUSEC = "cusec", "year"))

ses_cat_df <- as_tibble(ses_cat_sf) %>%
  select(-geometry)

write_csv(ses_cat_df, "data-processed/ses_cat.csv")
saveRDS(ses_cat_df, "data-processed/ses_cat_df.rds")
saveRDS(ses_cat_sf, "data-processed/ses_cat_sf.rds")

## Plots ===========================================================

plotMap <- function(data, stat) {
  tm_shape(data) +
    tm_fill(stat) +
    tm_borders(col = "white", alpha = 0.4) +
    tm_facets("year")
}

map_income_individual_cat <- plotMap(ses_cat_sf, "net_income_avg")
map_income_household_cat <- plotMap(ses_cat_sf, "net_income_avg_household")
map_income_individual_bcn <- ses_cat_sf %>%
  filter(NMUN == "Barcelona") %>%
  plotMap("net_income_avg")
map_income_household_bcn <- ses_cat_sf %>%
  filter(NMUN == "Barcelona") %>%
  plotMap("net_income_avg_household")
map_gini_cat <- plotMap(ses_cat_sf, "gini")
map_gini_bcn <- ses_cat_sf %>%
  filter(NMUN == "Barcelona") %>%
  plotMap("gini")

save(
  map_income_individual_cat,
  map_income_household_cat,
  map_gini_cat,
  map_income_individual_bcn,
  map_income_household_bcn,
  map_gini_bcn,
  file = "figs/maps.rds"
)

tmap_save(
  map_income_individual_cat,
  "figs/map_income_individual_cat.png", dpi = 300
)
tmap_save(
  map_income_individual_bcn,
  "figs/map_income_individual_bcn.png",
  dpi = 300
)
tmap_save(
  map_income_household_cat,
  "figs/map_income_household_cat.png",
  dpi = 300
)
tmap_save(
  map_income_household_bcn,
  "figs/map_income_household_bcn.png",
  dpi = 300
)
tmap_save(map_gini_cat, "figs/map_gini_cat.png", dpi = 300)
tmap_save(map_gini_bcn, "figs/map_gini_bcn.png", dpi = 300)
