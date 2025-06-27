# Adhesinome Project (Summer 2025)

## Computational pipeline to extract and annotate putative adhesins from a yeast pathogen proteome

**01-three-part-adhesin-test**: Run PredGPI, Fungal RV, SignalP, then plot in R

**02-adhesin-annotate**: Annotate putative adhesins (Pfam domains (hmmscan), Ser/Thr frequency (EMBOSS), Beta aggregation seq (Tango), Tandem Repeats (XSTREAM))

See detailed README.md files in 01-three-part-adhesin-test and 02-adhesin-annotate

### If Linux system, do the following to run 01-three-part-adhesin-test:

#### For FungalRV, create links to bin-linux compilations

```
cd FungalRV_adhesin_predictor
rm ./calc_dipep_freq
ln -s bin-linux/calc_dipep_freq ./calc_dipep_freq
rm ./calc_aafreq
ln -s bin-linux/calc_aafreq ./calc_aafreq
rm ./calc_hdr_comp
ln -s bin-linux/calc_hdr_comp ./calc_hdr_comp
rm ./calc_multiplets
ln -s bin-linux/calc_multiplets ./calc_multiplets
rm ./calc_tripep_freq
ln -s bin-linux/calc_tripep_freq ./calc_tripep_freq
```

#### Compile svm_light for Linux

```
cd FungalRV_adhesin_predictor/svm_light
make
mv svm_classify ../
```
