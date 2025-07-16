library(tidyverse)
library(ComplexUpset)
library(ggvenn)

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2){
  print("Usage: Rscript adhesinPlot.R <inputFile> <outputDirPath>")
  stop()
}

inputFile <- args[1]
outputDir <- args[2]

adhesinData <- read.csv(file = inputFile)
if (!dir.exists(outputDir)) {
  dir.create(outputDir, recursive = TRUE)
}
outputFile <- file.path(outputDir, "part1Plots.pdf")
pdf(outputFile, width = 8, height = 6)

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

dev.off()