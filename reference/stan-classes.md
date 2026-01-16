# S7 classes for estimation specifications

The constructors for Stan back-ends and methods are exported to support
extensions to measr, for example converting other models to `measrfit`
objects. We do not expect or recommend calling these functions directly
unless you are converting objects, or creating new methods for measrfit
objects.

## Usage

``` r
rstan()

cmdstanr()

mcmc()

optim()

variational()

pathfinder()

gqs()
```

## Value

An [S7
object](https://rconsortium.github.io/S7/reference/S7_object.html) with
the corresponding class.

## Details

### Back-end classes

There are two classes for estimation backends, which define the package
that should be used, or was used, to estimate a model. Both classes
inherit from `measr::stanbackend`.

- The `rstan()` class indicates use of the `{rstan}` package.

- `cmdstanr()` indicates use of the `{cmdstanr}` package.

### Method classes

The method classes define which estimation method should be used, or was
used, for a model. All method classes inherit from `measr::stanmethod`.

- The `mcmc()` class indicates the use of Markov chain Monte Carlo via
  [`rstan::sampling()`](https://mc-stan.org/rstan/reference/stanmodel-method-sampling.html)
  when using `{rstan}` or the
  [`$sample()`](https://mc-stan.org/cmdstanr/reference/model-method-sample.html)
  method of the
  [CmdStanModel](https://mc-stan.org/cmdstanr/reference/CmdStanModel.html)
  class when using `{cmdstanr}`.

- The `variational()` class indicated the use of Stan's variational
  algorithm for approximate posterior sampling via
  [`rstan::vb()`](https://mc-stan.org/rstan/reference/stanmodel-method-vb.html)
  when using `{rstan}` or the
  [`$variational()`](https://mc-stan.org/cmdstanr/reference/model-method-variational.html)
  method of the
  [CmdStanModel](https://mc-stan.org/cmdstanr/reference/CmdStanModel.html)
  class when using `{cmdstanr}`.

- The `pathfinder()` class indicates the use of pathfinder variational
  inference algorithm via the
  [`$pathfinder()`](https://mc-stan.org/cmdstanr/reference/model-method-pathfinder.html)
  method of the
  [CmdStanModel](https://mc-stan.org/cmdstanr/reference/CmdStanModel.html).
  This method is only available when using `{cmdstanr}`.

- The `optim()` class indicates the use maximum-likelihood via
  [`rstan::optimizing()`](https://mc-stan.org/rstan/reference/stanmodel-method-optimizing.html)
  when using `{rstan}` or the
  [`$optimize()`](https://mc-stan.org/cmdstanr/reference/model-method-optimize.html)
  method of the
  [CmdStanModel](https://mc-stan.org/cmdstanr/reference/CmdStanModel.html)
  class when using `{cmdstanr}`.

- Finally, there is a `gqs()` class for use when a model has previously
  been estimated and were are interested in calculating generated
  quantities (e.g.,
  [`score()`](https://measr.r-dcm.org/reference/score.md),
  [`loglik_array()`](https://measr.r-dcm.org/reference/loglik_array.md)).
  The `gqs()` class indicates the use of
  [`rstan::gqs()`](https://mc-stan.org/rstan/reference/stanmodel-method-gqs.html)
  when using `{rstan}` and the
  [`$generate_quantities()`](https://mc-stan.org/cmdstanr/reference/model-method-generate-quantities.html)
  method of the
  [CmdStanModel](https://mc-stan.org/cmdstanr/reference/CmdStanModel.html)
  class when using `{cmdstanr}`.

## Examples

``` r
rstan()
#> <measr::rstan>

mcmc()
#> <measr::mcmc>
```
