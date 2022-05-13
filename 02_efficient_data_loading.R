# Reading and processing data efficiently
# packages
library(tidyverse)
library(haven)

# reading the data
# persoontab (14 MB) full and then select
persoon <- 
  read_spss(file = "raw_data/GBAPERSOONTAB/GBAPERSOON2018TABV2.sav") |> 
  select(c(RINPERSOON, RINPERSOONS, GBAGESLACHT)) |> 
  mutate(GBAGESLACHT = as_factor(GBAGESLACHT))

# persoontab with col_select argument
persoon <- 
  read_spss(file = "raw_data/GBAPERSOONTAB/GBAPERSOON2018TABV2.sav", 
            col_select = c(RINPERSOON, RINPERSOONS, GBAGESLACHT)) |> 
  mutate(GBAGESLACHT = as_factor(GBAGESLACHT))

# inpatab (5.3 MB)
inpa <- 
  read_spss(file = "raw_data/INPATAB/INPA2018TABV2.sav") |> 
  mutate(income_log = log1p(INPPERSBRUT)) |> 
  select(-INPPERSBRUT)

# combine
dat_2018 <- left_join(
  x = persoon, 
  y = inpa, 
  by = c("RINPERSOON", "RINPERSOONS")
)

# writing the data (1.7MB)
write_rds(dat_2018, "processed_data/dat_2018.rds")

# done!