# SU25-adhesinome

## Computational pipeline to extract and analyze putative adhesins from a yeast pathogen proteome

### If Linux system:

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

### Command Usage

./adhesinPipeline.sh \<inputFile\> \<outputFile\>
