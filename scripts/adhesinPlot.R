library(tidyverse)
library(ComplexUpset)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2){
  print("Usage: Rscript adhesinPlot.R <inputFile> <outputFile>")
  stop()
}

adhesinData <- read.csv(file = args[1])

adhesinData |> 
  ggplot(aes(x = FungalRV.Score, fill = factor(GPI.anchor))) + 
  geom_density(alpha = 0.5) +
  geom_vline(xintercept = 0.511, linetype = "dashed", 
             color = "red", linewidth = 1) +
  labs(title = "FungalRV Scores", 
       x = "FungalRV Score", y = "Density")

adhesinData |> 
  ggplot(aes(x = FungalRV.Score)) + 
  geom_density(fill = "skyblue", alpha = 0.5) +
  geom_vline(xintercept = 0.511, linetype = "dashed", 
             color = "red", linewidth = 1) +
  labs(title = "FungalRV Scores", 
       x = "FungalRV Score", y = "Density")

# UpSet Plot
totalProteins <- nrow(adhesinData)

adhesinData |> 
  mutate(FungalRV.Positive = (FungalRV.Score > 0.511)) |>
  upset(intersect = c("FungalRV.Positive", "GPI.anchor"),
       name = "Putative Adhesins",
  )

ggsave(paste(filename = args[2], ".png", sep = ""))

  
