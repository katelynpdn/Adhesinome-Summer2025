library(gt)

countString <- "1 1 3 4 5 7 1 13 4 1 1 1 1 2 1 3 1 1 1 24 5 1 1 4 5 2 1 1 1 4 4 2 2 1 5 5 1 1 1 1 1 8"
countList <- unlist(strsplit(countString, split = " "))

speciesString <- "Saccharomyces_cerevisiae
Eremothecium_gossypii
Scheffersomyces_stipitis
Meyerozyma_guilliermondii
Lodderomyces_elongisporus
Candida_dubliniensis
Zygosaccharomyces_rouxii
Candida_tropicalis
Lachancea_thermotolerans
Clavispora_lusitaniae
Eremothecium_cymbalariae
Naumovozyma_dairenensis
Naumovozyma_castellii
Torulaspora_delbrueckii
Tetrapisispora_phaffii
Candida_orthopsilosis
Kazachstania_africana
Tetrapisispora_blattae
Yamadazyma_tenuis
Spathaspora_passalidarum
Wickerhamomyces_ciferrii
Debaryomyces_fabryi
Saccharomyces_eubayanus
Wickerhamomyces_anomalus
Cyberlindnera_jadinii
Hyphopichia_burtonii
Kazachstania_naganishii
Lachancea_lanzarotensis
Kluyveromyces_marxianus
Candida_pseudohaemulonii
Candida_duobushaemulonis
Candida_haemuloni
Candida_auris
Saccharomyces_paradoxus
Candida_parapsilosis
Zygotorulaspora_mrakii
Saccharomyces_mikatae
Saccharomyces_kudriavzevii
Candida_glabrata
Kluyveromyces_lactis
Debaryomyces_hansenii
Candida_albicans"
speciesList <-  unlist(strsplit(speciesString, split = "\n"))

correctOrderString <- "Candida_duobushaemulonis
Candida_pseudohaemulonii
Candida_haemuloni
Candida_auris
Clavispora_lusitaniae
Hyphopichia_burtonii
Candida_dubliniensis
Candida_albicans
Candida_tropicalis
Candida_parapsilosis
Candida_orthopsilosis
Lodderomyces_elongisporus
Spathaspora_passalidarum
Scheffersomyces_stipitis
Meyerozyma_guilliermondii
Debaryomyces_hansenii
Debaryomyces_fabryi
Yamadazyma_tenuis
Naumovozyma_dairenensis
Naumovozyma_castellii
Kazachstania_naganishii
Kazachstania_africana
Saccharomyces_paradoxus
Saccharomyces_cerevisiae
Saccharomyces_mikatae
Saccharomyces_kudriavzevii
Saccharomyces_eubayanus
Candida_glabrata
Tetrapisispora_phaffii
Tetrapisispora_blattae
Torulaspora_delbrueckii
Zygotorulaspora_mrakii
Zygosaccharomyces_rouxii
Kluyveromyces_marxianus
Kluyveromyces_lactis
Eremothecium_cymbalariae
Eremothecium_gossypii
Lachancea_thermotolerans
Lachancea_lanzarotensis
Wickerhamomyces_ciferrii
Wickerhamomyces_anomalus
Cyberlindnera_jadinii"
speciesList2 <-  unlist(strsplit(correctOrderString, split = "\n"))

countList2 <- c()
for (i in speciesList2) {
  countList2 <- append(countList2, countList[which(speciesList == i)])
}

df <- data.frame("Species" = speciesList2, "Count" = as.numeric(countList2))

df |> 
  gt() |>
  data_color(columns = Count, 
             fn = scales::col_numeric(
               palette = c("#FFE5D9", "#FF5733"),  # light to intense color
               domain = c(1, 24) )
               ) |>
  opt_table_font(weight = 800)
