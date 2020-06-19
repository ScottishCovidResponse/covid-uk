# covid-uk

Stochastic age-structured model of SARS-nCoV-2 transmission for UK scenario projections.

## Quick start guide

### Installing dependencies for Mac OS

You will need to install gfortran binaries from here: https://github.com/fxcoudert/gfortran-for-macOS/releases

Once installed, run `gcc --version` in terminal to get your current version, e.g. `Target: x86_64-apple-darwin18.8.2.0`. Then run below in terminal to add library path for R:

`cd ~
mkdir .R
cd .R
echo FLIBS=-L/usr/local/gfortran/lib/gcc/x86_64-apple-darwin18/8.2.0 -L/usr/local/gfortran/lib -lgfortran -lquadmath -lm >> Makevars
`

Finally, install nlopt: `brew install nlopt`

### Guide to files

Main parameter setting and model run script is in `UK.R` – there is option to set local path at top. Output collation and plotting functions are in `UK-view.R`. Underlying model code is in `covidm` folder.

To run `UK.R`, after editing the local path at the top of the script, invoke as follows from the command line:
`Rscript UK.R 1 50`
Here, 1 is the number for the analysis you want to run (1, 2.1, 2.2, 3, 4, 5, or 6). 50 is the number of stochastic realisations to run.

1 - 12 week interventions

2.1 - national triggering

2.2 - local triggering

3 - lockdowns

4 - elder care during school closures

5 - R0 analysis

6 - leisure and sports analyses

For 50 runs, each set takes about 6-16 hours on a current laptop.

Additional arguments exist to specify the location of the parameters file (example found in `params/params.ini`) and the location of this repository (if running the script from elsewhere):
```
UK.R 1 50 --parameters=./params/params.ini --covid-uk-path=$PWD
```

## Testing After Development

The R scripts require libaries to be installed (see the `Dockerfile` which contains a list of bash commands showing installation of these) and have been confirmed to run with Rscript `v4.0.0`.

Included within the repository is a set of tests which are designed to be run from a development branch, they compare the results obtained with the current scripts to those obtained with running the original source code from the parent repository. It is recommended you run within the root of this repository:

`./scripts/run_tests.sh`

which will run the relevant R code followed by the Python nose tests.
The tests require you to install the modules contained within the `tests/requirements.txt` file.

## Running on Docker (Recommended)

The repository contains a Dockerfile which can be used to build an image, from within the repository run:

`docker build -t coviduk .`

a container can then be created in which you should mount this repository:

`docker run --name coviduk --mount type=bind,source=/path/to/this/repository,target=/home/coviduk/covid-uk -ti coviduk:latest`

This will create a new container called `coviduk` which can be started and stopped using:

`docker start coviduk`
`docker stop coviduk`

Open a terminal within the container by using:

`docker attach coviduk`

you can then use the `bash run_all.sh` command.

Using a Docker allows you to make changes in the repository on your local machine, then test them by launching the container and running the scripts within the already prepared environment.

### Reference

[Davies NG et al. The effect of non-pharmaceutical interventions on COVID-19 cases, deaths and demand for hospital services in the UK: a modelling study. CMMID COVID-19 working group pre-print, 2020.](https://cmmid.github.io/topics/covid19/control-measures/uk-scenario-modelling.html)
