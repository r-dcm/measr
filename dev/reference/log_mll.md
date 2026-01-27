# Log marginal likelihood calculation

Calculate the log marginal likelihood with bridge sampling (Meng & Wong,
1996). This is a wrapper around
[`bridgesampling::bridge_sampler()`](https://rdrr.io/pkg/bridgesampling/man/bridge_sampler.html).
Therefore, log marginal likelihood calculation is currently only
available for models estimated with `{rstan}` using MCMC.

## Usage

``` r
log_mll(x, ..., force = FALSE)
```

## Arguments

- x:

  A [measrdcm](https://measr.r-dcm.org/dev/reference/dcm_estimate.md)
  object estimated with `backend = "optim"`.

- ...:

  Unused.

- force:

  If the criterion has already been added to the model object with
  [`add_criterion()`](https://measr.r-dcm.org/dev/reference/model_evaluation.md),
  should it be recalculated. Default is `FALSE`.

## Value

The estimate of the log marginal likelihood.

## References

Meng, X.-L., & Wong, W. H. (1996). Simulating ratios of normalizing
constants via a simple identity: A theoretical exploration. *Statistical
Sinica, 6*(4), 831-860. <https://www.jstor.org/stable/24306045>

## Examples

``` r
model_spec <- dcm_specify(
  qmatrix = dcmdata::mdm_qmatrix,
  identifier = "item"
)
model <- dcm_estimate(
  dcm_spec = model_spec,
  data = dcmdata::mdm_data,
  identifier = "respondent",
  method = "variational",
  seed = 63277
)
#> Chain 1: ------------------------------------------------------------
#> Chain 1: EXPERIMENTAL ALGORITHM:
#> Chain 1:   This procedure has not been thoroughly tested and may be unstable
#> Chain 1:   or buggy. The interface is subject to change.
#> Chain 1: ------------------------------------------------------------
#> Chain 1: 
#> Chain 1: 
#> Chain 1: 
#> Chain 1: Gradient evaluation took 0.000129 seconds
#> Chain 1: 1000 transitions using 10 leapfrog steps per transition would take 1.29 seconds.
#> Chain 1: Adjust your expectations accordingly!
#> Chain 1: 
#> Chain 1: 
#> Chain 1: Begin eta adaptation.
#> Chain 1: Iteration:   1 / 250 [  0%]  (Adaptation)
#> Chain 1: Iteration:  50 / 250 [ 20%]  (Adaptation)
#> Chain 1: Iteration: 100 / 250 [ 40%]  (Adaptation)
#> Chain 1: Iteration: 150 / 250 [ 60%]  (Adaptation)
#> Chain 1: Iteration: 200 / 250 [ 80%]  (Adaptation)
#> Chain 1: Success! Found best value [eta = 1] earlier than expected.
#> Chain 1: 
#> Chain 1: Begin stochastic gradient ascent.
#> Chain 1:   iter             ELBO   delta_ELBO_mean   delta_ELBO_med   notes 
#> Chain 1:    100         -359.619             1.000            1.000
#> Chain 1:    200         -356.482             0.504            1.000
#> Chain 1:    300         -357.533             0.337            0.009
#> Chain 1:    400         -356.970             0.253            0.009
#> Chain 1:    500         -356.577             0.203            0.003
#> Chain 1:    600         -356.663             0.169            0.003
#> Chain 1:    700         -356.504             0.145            0.002
#> Chain 1:    800         -356.213             0.127            0.002
#> Chain 1:    900         -356.102             0.113            0.001
#> Chain 1:   1000         -357.671             0.102            0.002
#> Chain 1:   1100         -356.013             0.003            0.002
#> Chain 1:   1200         -356.499             0.002            0.001
#> Chain 1:   1300         -355.419             0.002            0.001
#> Chain 1:   1400         -355.379             0.002            0.001
#> Chain 1:   1500         -356.771             0.002            0.001
#> Chain 1:   1600         -355.933             0.002            0.002
#> Chain 1:   1700         -356.108             0.002            0.002
#> Chain 1:   1800         -356.069             0.002            0.002
#> Chain 1:   1900         -356.345             0.002            0.002
#> Chain 1:   2000         -356.950             0.002            0.002
#> Chain 1:   2100         -356.320             0.002            0.002
#> Chain 1:   2200         -356.238             0.001            0.002
#> Chain 1:   2300         -355.858             0.001            0.001
#> Chain 1:   2400         -355.771             0.001            0.001
#> Chain 1:   2500         -355.857             0.001            0.001   MEAN ELBO CONVERGED   MEDIAN ELBO CONVERGED
#> Chain 1: 
#> Chain 1: Drawing a sample of size 2000 from the approximate posterior... 
#> Chain 1: COMPLETED.
#> Warning: Pareto k diagnostic value is 1.09. Resampling is disabled. Decreasing tol_rel_obj may help if variational algorithm has terminated prematurely. Otherwise consider using sampling instead.

log_mll(model)
#> [1] -349.5096
```
