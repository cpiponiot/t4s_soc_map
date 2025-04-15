# All data

Apr 15, 2025

This folder contains the datasets used in the analyses. The three main
files of the terri4sol soil database are:

- `soil_0.2.2.csv` contains soil measurements for each site, plot and
  soil depth (1: 0-10 cm, 2: 10-20 cm, 3: 20-30 cm);

- `use_0.2.2.csv` describes landuses in each plot over different periods
  of time (from `Starting_date` to `End_date`);

- `plot_0.2.2.csv` provides plot-level information.

The `download` folder contains files that are downloaded with the codes
in this repository.

The `cache` folder contains intermediate data files created during
analysis.

``` r
fs::dir_tree(recurse = 1, regexp = "[.]csv$")
```

    .
    ├── plot_0.2.2.csv
    ├── soil_0.2.2.csv
    └── use_0.2.2.csv
