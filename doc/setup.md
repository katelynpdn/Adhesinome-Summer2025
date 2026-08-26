# Setup and Installation

Steps 1 and 2 below are needed for Linux systems, otherwise they can be skipped if using a Mac.

## 1. FungalRV Adhesin Predictor

The 01-three-part-adhesin-test analysis requires the FungalRV Adhesin Predictor. The FungalRV directory contains both precompiled Linux and Mac executables in the bin-linux/ and bin-mac/ directories respectively.

If using a Linux system, create symbolic links from the expected executable names to the Linux binaries.

From the FungalRV_adhesin_predictor directory:

```
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

## 2. SVM-light

In the FungalRV_adhesin_predictor/svm_light directory, compile the software then move it to the parent FungalRV directory.

```
make
mv svm_classify ../
```

## 3. PredGPI

Set and export PREDGPI_HOME to point to the program directory:

```
$ export PREDGPI_HOME='/path/to/src/predgpi'
```

Replace /path/to with the path to this repository.

## 4. Install HMMER

Installation varies depending on the operating system.

### Conda

```
conda install bioconda::hmmer
```

Verify HMMER installed with

```
hmmsearch -h
```

## 5. Download and Prepare Pfam

```
wget https://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam37.4/Pfam-A.hmm.gz
gunzip Pfam-A.hmm.gz
hmmpress Pfam-A.hmm
```

## 6. Install EMBOSS

### Conda

```
conda install bioconda::emboss
```

After installing or compiling EMBOSS, set:

```
export EMBOSS_HOME="/path/to/EMBOSS-6.6.0"
export PATH="$EMBOSS_HOME/emboss:$PATH"
export LD_LIBRARY_PATH="$EMBOSS_HOME/emboss/.libs:$LD_LIBRARY_PATH"
export EMBOSS_ACDROOT="$EMBOSS_HOME/emboss/acd"
```

Replace /path/to/EMBOSS-6.6.0 with the location of your EMBOSS installation.
