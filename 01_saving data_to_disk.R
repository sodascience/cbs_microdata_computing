# saving a dataset in different formats
library(tidyverse)
library(palmerpenguins)

df <- penguins_raw

# saving as csv
write_csv(df, "processed_data/penguins.csv")

# serializing to .rds (binary format)
write_rds(df, "processed_data/penguins.rds")

# serializing to compressed .rds (longer load times)
write_rds(df, "processed_data/penguins_compressed.rds", 
          compress = "xz")