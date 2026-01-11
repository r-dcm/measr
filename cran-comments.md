## Release summary

This is a major release to update the user API add some several new features.

## Test environments

* local R installation macOS Tahoe 26.2, R 4.5.2
* macOS Sequoia 15.7.2 (on github actions), R 4.5.2
* windows server 2022 x64 (on github actions), R 4.5.2
* ubuntu 24.04.3 LTS (on github actions), R-devel
* ubuntu 24.04.3 LTS (on github actions), R 4.5.2
* ubuntu 24.04.3 LTS (on github actions), R 4.4.3
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 3 notes

* cmdstanr is a suggested package not on CRAN. Its availability is indicated in the Additional_repositories field in the DESCRIPTION. The cmdstanr package is completely optional, and is an alternative to rstan (also imported) for estimating models. The default behavior is to use rstan, but cmdstanr functionality is provided for users who may prefer that interface to the 'Stan' language.

* RcppParallel and rstantools are declared imports and not used directly by this package, but are needed for the configuration (e.g., `configure` and `configure.win`) and compiling the 'Stan' models.

* GNU make is a system requirement for compiling the 'Stan' models.
