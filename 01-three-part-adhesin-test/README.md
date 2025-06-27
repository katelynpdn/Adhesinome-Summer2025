# Perform 3-part-test to identify putative adhesins: PredGPI, Fungal RV, SignalP

### Command Usage

./adhesinPipeline.sh \<inputFile\> \<outputFile\>

File tree (for files of note)

```
├── FungalRV_adhesin_predictor      # From binhe-lab/2023-adhesin-parallel-evolution (one file modified)
│   ├── bin-linux
│   ├── bin-mac
│   ├── binaries for ia32 bit machine
│   ├── calc_aafreq -> bin-mac/calc_aafreq
│   ├── calc_aafreq.c
│   ├── calc_dipep_freq -> bin-mac/calc_dipep_freq
│   ├── calc_dipep_freq.c
│   ├── calc_hdr_comp -> bin-mac/calc_hdr_comp
│   ├── calc_hdr_comp.c
│   ├── calc_multiplets -> bin-mac/calc_multiplets
│   ├── calc_multiplets.c
│   ├── calc_tripep_freq -> bin-mac/calc_tripep_freq
│   ├── calc_tripep_freq.c
│   ├── run_fungalrv_adhesin_predictor.pl       # Modified to accept file path as input
│   ├── svm_classify        # Required dependency
│   ├── svm_light           # Compile the following to get svm_classify (Instructions in Adhesinome-Summer2025/README.md)
    └── ...
├── README.md               # This is where you are
├── adhesinPipeline.sh      # Main pipeline (calls scripts in scripts/)
├── data                    # Folder to put input data (proteome)
├── plots
│   └── adhesinPlot.R       # R script to generate plots of results
├── predgpi                 # Modified PredGPI to remove the error: `np.int` was a deprecated alias for the builtin `int`
│   ├── predgpi.py
│   └── ...
├── results                 # Folder to put results
└── scripts
    ├── extractSeq.py       # Extract protein IDs with a good FungalRV cutoff and a GPI-anchor
    ├── fastaRemoveX.py     # Remove any X's in a FASTA file
    ├── parse_all_output.py # Combine FungalRV, PredGPI, and SignalP output
    ├── runSignalP.sh       # Run SignalP predictor on a FASTA file
    └── splitFasta.py       # Split FASTA file into chunks of 300 (or less) sequences
```
