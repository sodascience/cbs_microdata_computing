# saving a dataset in different formats
library(tidyverse)
library(palmerpenguins)

df <- penguins_raw

# saving as csv
write_csv(df, "processed_data/penguins.csv")

# serializing to compressed .rds
write_rds(df, "processed_data/penguins.rds", compress = "xz")

# reading from .rds
df <- read_rds("processed_data/penguins.rds")
