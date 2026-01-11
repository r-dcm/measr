# measr

Diagnostic classification models (DCMs) are a class of psychometric
models that estimate respondent abilities as a profile of proficiency on
a pre-defined set of skills, or attributes. Despite the utility of DCMs
for providing fine-grained and actionable feedback with shorter
assessments, they have are not widely used in applied settings, in part
due to a lack of user-friendly software. Using
[R](https://www.r-project.org/) and [Stan](https://mc-stan.org/), measr
(said: “measure”) simplifies the process of estimating and evaluating
DCMs. Users can specify different DCM subtypes, define prior
distributions, and estimate the model using the
[rstan](https://mc-stan.org/rstan/) or
[cmdstanr](https://mc-stan.org/cmdstanr/) interface to Stan. You can
then easily examine model parameters, calculate model fit metrics,
compare competing models, and evaluate the reliability of the
attributes.

## Installation

You can install the released version of measr from
[CRAN](https://cran.r-project.org/) with:

``` r
install.packages("measr")
```

To install the development version of measr from
[GitHub](https://github.com/r-dcm/measr) use:

``` r
# install.packages("remotes")
remotes::install_github("r-dcm/measr")
```

Because measr is based on Stan, a C++ compiler is required. For Windows,
the [Rtools program](https://cran.r-project.org/bin/windows/Rtools/)
comes with a C++ compiler. On Mac, it’s recommended that you install
Xcode. For additional instructions and help setting up the compilers,
see the [RStan installation help
page](https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started).

## Usage

We can define a DCM using
[`dcm_specify()`](https://dcmstan.r-dcm.org/reference/dcm_specify.html).
This function requires a Q-matrix defining which attributes are measured
by each item. We also identify any item identifier columns. Other
arguments can be specified to customize the type of model to estimate
(e.g., type of measurement or structural model; see
`?dcmstan::dcm_specify()`). We can then estimate our specified DCM using
[`dcm_estimate()`](https://measr.r-dcm.org/dev/reference/dcm_estimate.md).
We supply our specification and our data set, along with any respondent
identifiers. As with
[`dcm_specify()`](https://dcmstan.r-dcm.org/reference/dcm_specify.html),
other arguments can be specified to customize the model estimation
process (e.g., estimation backend and method; see `?dcm_estimate()`).

To demonstrate measr’s functionality, example data sets are available in
the [dcmdata](https://dcmdata.r-dcm.org) package. Here we use the
Examination of Certificate of Proficiency in English (ECPE; [Templin &
Hoffman, 2013](https://doi.org/10.1111/emip.12010)) data (see
[`?dcmdata::ecpe`](https://dcmdata.r-dcm.org/reference/ecpe.html) for
details). Note that by default, measr uses a full Markov chain Monte
Carlo (MCMC) estimation with Stan, which can be time and computationally
intensive. For a quicker estimation, we could use Stan’s optimizer
instead of MCMC by adding `method = "optim"` to the function call.
However, please note that some functionality will be lost when using the
optimizer (e.g., the calculation of some model fit criteria requires the
use of MCMC).

``` r
library(measr)

model_spec <- dcm_specify(dcmdata::dtmr_qmatrix, identifier = "item")

model <- dcm_estimate(
  dcm_spec = model_spec,
  data = dcmdata::dtmr_data,
  identifier = "id",
  seed = 69385,
  refresh = 0
)
```

Once a model has been estimated, model parameters, respondent
classifications, and results of the model fit analyses can then be
extracted using
[`measr_extract()`](https://measr.r-dcm.org/dev/reference/measr_extract.md).

``` r
measr_extract(model, "m2")
#> # A tibble: 1 × 3
#>      m2    df  pval
#>   <dbl> <int> <dbl>
#> 1  261.   293 0.909

measr_extract(model, "classification_reliability")
#> # A tibble: 4 × 3
#>   attribute                 accuracy consistency
#>   <chr>                        <dbl>       <dbl>
#> 1 referent_units               0.928       0.878
#> 2 partitioning_iterating       0.924       0.875
#> 3 appropriateness              0.894       0.817
#> 4 multiplicative_comparison    0.924       0.867
```

------------------------------------------------------------------------

Contributions are welcome. To ensure a smooth process, please review the
[Contributing Guide](https://measr.r-dcm.org/CONTRIBUTING.html). Please
note that the measr project is released with a [Contributor Code of
Conduct](https://measr.r-dcm.org/CODE_OF_CONDUCT.html). By contributing
to this project, you agree to abide by its terms.
