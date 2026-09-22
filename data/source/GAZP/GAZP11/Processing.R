setwd("C:\\Users\\Nancy Shackelford\\Documents\\Post-doctoral Research\\GAZP\\Datasets\\GAZP11")
library(tidyverse)

sps <- read.csv("Species.csv")
dat <- read.csv("NV_seedlings_edit.csv")
colnames(dat)[1] <- "ID"

dat_new <- dat %>%
  group_by(ID, Rep, Time, Species, Seed_Rate) %>%
  summarize(Area = length(Block),
            Density = sum(Seeded_Seedlings))

colnames(sps)[1] <- "Code"

dat_new <- dat_new[-1, ]
colnames(dat_new)[4] <- "Code"
dat_new <- dat_new %>%
  left_join(sps)

dat_new$Rate <- 1
dat_new$Rate[dat_new$Seed_Rate == "high"] <- 2

dat_new <- dat_new %>%
  mutate(Seeds = Rate * Seeded)
write.csv(dat_new, "Rout.csv", row.names = FALSE)
