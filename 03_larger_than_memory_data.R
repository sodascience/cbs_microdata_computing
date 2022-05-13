# Working with larger-than-memory data
library(tidyverse)
library(DBI)
library(RSQLite)
library(biglmm)

# Task 1: Plotting ----
# a descriptive plot of mean income per year and per sex

## Option 1: chunked data ----
for (yr in 2000L:2020L) {
  dat <- 
    read_rds("processed_data/dat_2018.rds") |> 
    mutate(year = yr, income_log = income_log + rnorm(n(), 0.01*(yr-2000), sd = 0.001), 
           GBAGESLACHT = factor(GBAGESLACHT))
  filename <- paste0("processed_data/panel_data/dat_", yr, ".rds")
  write_rds(dat, filename)
}

fns <- list.files("processed_data/panel_data", full.names = TRUE)

tab <- 
  read_rds(fns[1]) |> 
  group_by(GBAGESLACHT) |> 
  summarize(income = exp(mean(income_log))) |> 
  mutate(year = 2000)

for (i in 2:length(fns)) {
  tab <- tab |> 
    bind_rows(
      read_rds(fns[i]) |> 
      group_by(GBAGESLACHT) |> 
      summarize(income = exp(mean(income_log))) |> 
      mutate(year = 1999 + i)
    )
}

tab |> 
  ggplot(aes(x = year, y = income, colour = GBAGESLACHT)) +
  geom_point() +
  geom_line() +
  scale_colour_viridis_d() +
  theme_minimal()


## Option 2: use a database ----
sql_db <- dbConnect(SQLite(), dbname = "processed_data/panel.db")
for (fn in fns) dbWriteTable(sql_db, "income", read_rds(fn), append = TRUE)

# we create a tbl object
income_tbl <- tbl(sql_db, "income") 

# we can perform queries on this virtual table
count(income_tbl)

tab_sql <- 
  income_tbl |> 
  group_by(GBAGESLACHT, year) |> 
  summarise(income = exp(mean(income_log)))

# lazy evaluation on the database
tab_sql |> show_query()
tab_sql

# create plot
tab_sql |> 
  ggplot(aes(x = year, y = income, colour = GBAGESLACHT)) +
  geom_point() +
  geom_line() +
  scale_colour_viridis_d() +
  theme_minimal()


# Task 2: Regression ----
# Are there differences in income between men and women & do these change over time?
coef_names <- c("(Intercept)", "Year", "Women - Men", "Unknown - Men", "Year : (Women - Men)", "Year : (Unknown - Men)")

## Option 1: Chunked regression ----
res <- biglm(
  formula = income_log ~ I(year-2000L) * factor(GBAGESLACHT, levels = c("Mannen", "Vrouwen", "Onbekend")), 
  data = read_rds(fns[1])
)

# update with data from the other chunks
for (fn in fns[-1]) res <- update(res, moredata = read_rds(fn))

# create a summary
s1 <- summary(res)
rownames(s1$mat) <- coef_names
s1

## Option 2: Regression on a database ----
res_sql <- bigglm(
  formula = income_log ~ I(year-2000L) * factor(GBAGESLACHT, levels = c("Mannen", "Vrouwen", "Onbekend")), 
  data = sql_db, tablename = "income"
)

# create a summary
s2 <- summary(res_sql)
rownames(s2$mat) <- coef_names
s2


# Disconnect from the database
dbDisconnect(sql_db)

