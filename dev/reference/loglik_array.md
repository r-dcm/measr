# Extract the log-likelihood of an estimated model

`loglik_array()` calculates the log-likelihood for an estimated model
via the generated quantities functionality in *Stan* and returns the
draws of the `log_lik` parameter.

## Usage

``` r
loglik_array(model, ...)
```

## Arguments

- model:

  A [measrdcm](https://measr.r-dcm.org/dev/reference/dcm_estimate.md)
  object.

- ...:

  Unused. For future extensions.

## Value

A
"[`draws_array`](https://mc-stan.org/posterior/reference/draws_array.html)"
object containing the log-likelihood estimates for the model.

## Methods

`loglik_array()` is an S7 generic with methods available for the
following classes:

- [`measr::measrdcm`](https://measr.r-dcm.org/dev/reference/measrdcm.md)

## Examples

``` r
rstn_mdm_lcdm <- dcm_estimate(
  dcm_specify(dcmdata::mdm_qmatrix, identifier = "item"),
  data = dcmdata::mdm_data,
  missing = NA,
  identifier = "respondent",
  method = "optim",
  seed = 63277,
  backend = "rstan"
)

loglik_array(rstn_mdm_lcdm)
#> # A draws_array: 1 iterations, 1 chains, and 142 variables
#> , , variable = log_lik[1]
#> 
#>          chain
#> iteration    1
#>         1 -2.3
#> 
#> , , variable = log_lik[2]
#> 
#>          chain
#> iteration    1
#>         1 -2.3
#> 
#> , , variable = log_lik[3]
#> 
#>          chain
#> iteration    1
#>         1 -2.3
#> 
#> , , variable = log_lik[4]
#> 
#>          chain
#> iteration    1
#>         1 -2.3
#> 
#> # ... with 138 more variables
```
