library(tidyverse)
library(here) 
library(srvyr)
library(survey)

ipums_data <- here("data",
                   "usa_00009.csv.gz") |>
  read_csv() |>
  filter(GQ != 3 & GQ != 4) 

data_2009 <- ipums_data |>
  filter(YEAR == 2009 & HHINCOME > 100000) |>
  group_by(SERIAL) |>
  summarise(CLUSTER = first(CLUSTER),
            STRATA = first(STRATA),
            HHWT = first(HHWT),
            HHINCOME = first(HHINCOME)) |>
  as_survey_design(ids = CLUSTER,
                   weights = HHWT)

survey::svyquantile(~HHINCOME, data_2009, 0.5)

data_2017 <- ipums_data |>
  filter(YEAR == 2017 & HHINCOME > 200000) |>
  group_by(SERIAL) |>
  summarise(CLUSTER = first(CLUSTER),
            STRATA = first(STRATA),
            HHWT = first(HHWT),
            HHINCOME = first(HHINCOME)) |>
  as_survey_design(ids = CLUSTER,
                   weights = HHWT)

survey::svyquantile(~HHINCOME, data_2017, 0.5)
