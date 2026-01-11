# Changelog

## measr (development version)

### Breaking changes

- The S3 parts of measr have been converted to
  [S7](https://rconsortium.github.io/S7/).

- Some of measr’s functionality has been decoupled into other packages
  to allow for quicker and easier updates. The generation of *Stan* code
  and data lists have been moved to
  [dcmstan](https://dcmstan.r-dcm.org). Similarly, the example data sets
  have been moved to [dcmdata](https://dcmdata.r-dcm.org) to facilitate
  the use of the data across other packages. As part of the decoupling,
  [`measr_dcm()`](https://measr.r-dcm.org/dev/reference/measr_dcm.md)
  has been deprecated in favor of
  [`dcmstan::dcm_specify()`](https://dcmstan.r-dcm.org/reference/dcm_specify.html)
  and
  [`dcm_estimate()`](https://measr.r-dcm.org/dev/reference/dcm_estimate.md).

  ``` r
  # old
  my_model <- measr_dcm(
    data = ecpe_data,
    qmatrix = ecpe_qmatrix,
    resp_id = "resp_id",
    item_id = "item_id",
    type = "lcdm",
    attribute_structure = "unconstrained",
    method = "mcmc"
  )

  # new
  library(dcmdata)

  my_spec <- dcm_specify(
    qmatrix = ecpe_qmatrix,
    identifier = "item_id",
    measurement_model = lcdm(),
    structural_model = unconstrained()
  )
  my_model <- dcm_estimate(
    dcm_spec = my_spec,
    data = ecpe_data,
    identifier = "resp_id",
    method = "mcmc"
  )
  ```

- [`predict()`](https://rdrr.io/r/stats/predict.html) has been
  deprecated in favor of
  [`score()`](https://measr.r-dcm.org/dev/reference/score.md). The
  functionality is the same, but

### New features

- [`aic()`](https://measr.r-dcm.org/dev/reference/aic-bic.md) and
  [`bic()`](https://measr.r-dcm.org/dev/reference/aic-bic.md) have been
  added for estimating relative model fit for models estimated with
  `method = "optim"`
  ([@JeffreyCHoover](https://github.com/JeffreyCHoover),
  [\#54](https://github.com/r-dcm/measr/issues/54)).

- [`bayes_factor()`](https://measr.r-dcm.org/dev/reference/bayes_factor.md)
  has been added for comparing models using Bayes factors. This is only
  available for models estimated with `backend = "rstan"`
  ([@JeffreyCHoover](https://github.com/JeffreyCHoover),
  [\#67](https://github.com/r-dcm/measr/issues/67)).

- Item and attribute discrimination measures can now be calculated with
  [`cdi()`](https://measr.r-dcm.org/dev/reference/cdi.md)
  ([@auburnhimenez34](https://github.com/auburnhimenez34),
  [\#63](https://github.com/r-dcm/measr/issues/63)).

- The specified Q-matrix can now be evaluated and compared to other
  empirical Q-matrix specifications using
  [`qmatrix_validation()`](https://measr.r-dcm.org/dev/reference/qmatrix_validation.md)
  ([@JeffreyCHoover](https://github.com/JeffreyCHoover),
  [\#65](https://github.com/r-dcm/measr/issues/65)).

- In
  [`reliability()`](https://measr.r-dcm.org/dev/reference/reliability.md),
  users can now calculate the classification accuracy and consistency
  for different probability classification threshold by specifying a
  `threshold` ([\#45](https://github.com/r-dcm/measr/issues/45)).

- New estimation methods,
  [`variational()`](https://measr.r-dcm.org/dev/reference/stan-classes.md)
  and
  [`pathfinder()`](https://measr.r-dcm.org/dev/reference/stan-classes.md),
  have been added to support estimation via *Stan’s* variational
  algorithm for approximate posterior sampling and the pathfinder
  variational inference algorithm, respectively. Pathfinder is only
  available when the model is estimated with
  [cmdstanr](https://mc-stan.org/cmdstanr/)
  ([\#72](https://github.com/r-dcm/measr/issues/72)).

- Local item dependence can now be estimated with
  [`yens_q3()`](https://measr.r-dcm.org/dev/reference/yens_q3.md)
  ([@JeffreyCHoover](https://github.com/JeffreyCHoover),
  [\#62](https://github.com/r-dcm/measr/issues/62)).

### Minor improvements and fixes

- Documentation has been updated to ensure examples use [Air
  formatting](https://posit-dev.github.io/air/) to improve accessibility
  ([\#68](https://github.com/r-dcm/measr/issues/68)).

- [`measr_extract()`](https://measr.r-dcm.org/dev/reference/measr_extract.md)
  has been updated to no longer require adding elements to a model
  object before extracting
  ([\#73](https://github.com/r-dcm/measr/issues/73)).

## measr 1.0.0

CRAN release: 2024-01-30

### New documentation

- A new article on model evaluation has been added to the project
  website (<https://measr.r-dcm.org>).

- The model estimation article has been updated to use the same
  (simulated) data set as the model evaluation article.

- More detailed installation instructions have been added to the getting
  started vignette ([\#23](https://github.com/r-dcm/measr/issues/23)).

- A case study demonstrating a full DCM-based analysis using data from
  the ECPE
  ([`?ecpe_data`](https://dcmdata.r-dcm.org/reference/ecpe.html)) has
  been added to the project website.

### Minor improvements and fixes

- Fixed bug in the LCDM specification of constraints for level-3 and
  above interaction terms.

- Functions for evaluating estimated models (e.g.,
  [`fit_ppmc()`](https://measr.r-dcm.org/dev/reference/fit_ppmc.md),
  [`reliability()`](https://measr.r-dcm.org/dev/reference/reliability.md))
  no longer recalculate indices if they have previously been saved to
  the model object. This behavior can be overwritten with
  `force = TRUE`.

- Updated *Stan* syntax to be compatible with the new array syntax
  ([@andrjohns](https://github.com/andrjohns),
  [\#36](https://github.com/r-dcm/measr/issues/36))

- [`get_parameters()`](https://dcmstan.r-dcm.org/reference/get_parameters.html)
  now preserves item identifiers by default. Items can be renamed with
  numbers (e.g., 1, 2, 3, …) by setting `rename_item = TRUE`.

- measr now reexports functions from
  [posterior](https://mc-stan.org/posterior/) for conducting
  mathematical operations on
  [`posterior::rvar()`](https://mc-stan.org/posterior/reference/rvar.html)
  objects.

- Respondent estimates are now returned as
  [`posterior::rvar()`](https://mc-stan.org/posterior/reference/rvar.html)
  objects when not summarized.

## measr 0.3.1

CRAN release: 2023-05-27

- Added a `NEWS.md` file to track changes to the package.

### New features

- Support for additional model specifications has been added
  ([\#10](https://github.com/r-dcm/measr/issues/10)):
  - The compensatory reparameterized unified model (C-RUM) can now be
    estimated by defining `type = "crum"` in the
    [`measr_dcm()`](https://measr.r-dcm.org/dev/reference/measr_dcm.md)
    function.
  - Users can now drop higher order interactions from the loglinear
    cognitive diagnostic model (LCDM). A new argument for
    [`measr_dcm()`](https://measr.r-dcm.org/dev/reference/measr_dcm.md),
    `max_interaction`, defines the highest order interactions to
    estimate. For example, `max_interaction = 2` will estimate only
    intercepts, main effects, and two-way interactions.
  - A new argument to
    [`measr_dcm()`](https://measr.r-dcm.org/dev/reference/measr_dcm.md),
    `attribute_structure` allows users to specified either
    “unconstrained” relationships between attributes or “independent”
    attributes.
- Updated prior specifications:
  - Users can now specify a prior distribution for the structural
    parameters that govern the base rates of class membership
    ([\#2](https://github.com/r-dcm/measr/issues/2)).
  - Safeguards were added to warn users when a specified prior is not
    defined for the chosen DCM sub-type. For example, an error is
    generated if a prior is defined for a slipping parameter, but the
    LCDM was chosen as the type of model to be estimated
    ([\#1](https://github.com/r-dcm/measr/issues/1)).

### Minor improvements and fixes

- Fixed bug with `backend = "rstan"` where warmup iterations could be
  more than the total iterations requested by the user if warmup
  iterations were not also specified
  ([\#6](https://github.com/r-dcm/measr/issues/6)).

- Additional specifications were added to
  [`measr_extract()`](https://measr.r-dcm.org/dev/reference/measr_extract.md)
  for extracting results from an estimated model.
