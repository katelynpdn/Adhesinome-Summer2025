# Annotate putative adhesins (Pfam domains, Serine/Threonine frequencies, Beta aggregation, Tandem repeats)

### Command Usage

### Setup

#### Download HMMER and PFAM

Installation varies based on your machine. For example,

```
brew install hmmer
wget https://ftp.ebi.ac.uk/pub/databases/Pfam/releases/Pfam37.4/Pfam-A.hmm.gz
gunzip Pfam-A.hmm.gz
hmmpress Pfam-A.hmm
```

Or on Argon HPC:

```
module load hmmer/3.3.2_gcc-9.3.0
```

#### Download EMBOSS

Installation varies based on your machine. For example,

```
wget ftp://emboss.open-bio.org/pub/EMBOSS/EMBOSS-6.6.0.tar.gz
tar -xzf EMBOSS-6.6.0.tar.gz
cd EMBOSS-6.6.0
./configure
make
vim ~/.bashrc
# Add export PATH="/Users/katelynnguyen/Downloads/EMBOSS-6.6.0/emboss:$PATH"
source ~/.bashrc
```

Note: To resolve the "libnucleus.so.6: cannot open shared object file: No such file or directory" and "ACD file not opened" errors on Argon HPC, I had to run:

```
export LD_LIBRARY_PATH=$(find /Users/knguyen19/EMBOSS-6.6.0 -type d -name ".libs" | tr '\n' ':' )$LD_LIBRARY_PATH
export EMBOSS_ACDROOT=/Users/knguyen19/EMBOSS-6.6.0/emboss/acd
```
