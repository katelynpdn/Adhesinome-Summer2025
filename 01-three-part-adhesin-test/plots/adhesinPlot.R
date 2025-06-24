library(tidyverse)
library(ComplexUpset)
library(ggvenn)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 1){
  print("Usage: Rscript adhesinPlot.R <inputFile>")
  stop()
}

adhesinData <- read.csv(file = args[1])

adhesinData |> 
  ggplot(aes(x = FungalRV.Score, fill = GPI.anchor)) + 
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

adhesinData |> 
  mutate(FungalRV.Positive = (FungalRV.Score > 0.511), 
         SignalP.Positive = (Signal.Peptide > 0.5)) |>
  upset(intersect = c("FungalRV.Positive", "GPI.anchor", "SignalP.Positive"),
       name = "Putative Adhesins",
  )

# Venn Diagram
adhesinData |> 
  mutate(FungalRV.Positive = (FungalRV.Score > 0.511), 
         SignalP.Positive = (Signal.Peptide > 0.5),
         GPI.anchor = as.logical(GPI.anchor)) |> ggvenn()