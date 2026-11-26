#' Log marginal likelihood calculation
#'
#' @description
#' Calculate the log marginal likelihood with bridge sampling (Meng & Wong,
#' 1996). This is a wrapper around [bridgesampling::bridge_sampler()].
#' Log marginal likelihoods are available for models estimated with either
#' backend (i.e., `{rstan}` or `{cmdstanr}`) using `method = "mcmc"` or
#' `method = "variational"`.
#'
#' # Methods
#' `log_mll()` is an S7 generic with methods available for the following
#' classes:
#'
#' `r doclisting::methods_list("log_mll")`
#'
#' @param x A [measrdcm][dcm_estimate()] object estimated with
#'   `method = "mcmc"` or `method = "variational"`.
#' @param ... Unused.
#' @param force If the criterion has already been added to the
#'   model object with [add_criterion()], should it be recalculated. Default is
#'   `FALSE`.
#'
#' @details
#' The bridge sampler evaluates the log density of the model using `{rstan}`. If
#' a compiled `{rstan}` model is not available (i.e., the model was estimated
#' with `backend = "cmdstanr"`), the model is compiled when `log_mll()` is
#' called. A model estimated with `{rstan}` in a previous *R* session is
#' restored from the saved model object.
#'
#' Bridge sampling assumes that the draws come from the posterior distribution.
#' The draws from `method = "variational"` are from an approximation to the
#' posterior, which can result in substantially biased log marginal likelihoods,
#' particularly for models with many parameters. We recommend `method = "mcmc"`
#' for calculating Bayes factors. For the same reason, log marginal likelihoods
#' are not available for models estimated with `method = "pathfinder"`.
#'
#' In addition, *Stan* writes draws to file with limited precision, which can
#' result in draws that are not valid parameter values (e.g., probabilities that
#' do not sum to exactly 1). Structural parameters are re-normalized to account
#' for this rounding, and any draws that are still invalid are excluded with a
#' warning.
#'
#' @return The estimate of the log marginal likelihood.
#' @export
#'
#' @references Meng, X.-L., & Wong, W. H. (1996). Simulating ratios of
#'   normalizing constants via a simple identity: A theoretical exploration.
#'   *Statistical Sinica, 6*(4), 831-860.
#'   <https://www.jstor.org/stable/24306045>
#'
#' @examplesIf measr_examples()
#' model_spec <- dcm_specify(
#'   qmatrix = dcmdata::mdm_qmatrix,
#'   identifier = "item"
#' )
#' model <- dcm_estimate(
#'   dcm_spec = model_spec,
#'   data = dcmdata::mdm_data,
#'   identifier = "respondent",
#'   method = "variational",
#'   seed = 63277
#' )
#'
#' log_mll(model)
log_mll <- S7::new_generic(
  "log_mll",
  "x",
  function(x, ..., force = FALSE) {
    S7::S7_dispatch()
  }
)

S7::method(log_mll, measrdcm) <- function(x, force = FALSE) {
  if (!rlang::is_empty(x@criteria$log_mll) && !force) {
    return(x@criteria$log_mll)
  }

  check_log_mll(x, arg = rlang::caller_arg(x))

  log_density <- rstan_log_density(x)
  log_marg_lik <- if (
    S7::S7_inherits(x@backend, rstan) && S7::S7_inherits(x@method, mcmc)
  ) {
    bridgesampling::bridge_sampler(
      x@model,
      stanfit_model = log_density,
      silent = TRUE
    )
  } else {
    draws <- unconstrain_draws(x, log_density)
    bounds <- rlang::set_names(rep(Inf, ncol(draws)), colnames(draws))
    bridgesampling::bridge_sampler(
      draws,
      log_posterior = eval_log_density,
      data = log_density,
      lb = -bounds,
      ub = bounds,
      silent = TRUE
    )
  }

  log_marg_lik$logml
}

check_log_mll <- function(x, arg, call = rlang::caller_env()) {
  if (
    S7::S7_inherits(x@method, mcmc) || S7::S7_inherits(x@method, variational)
  ) {
    return(invisible(x))
  }

  cli::cli_abort(
    glue::glue(
      "{{.arg {arg}}} must be a model estimated with ",
      "{{.code method = \"mcmc\"}} or {{.code method = \"variational\"}} to ",
      "calculate the marginal likelihood"
    ),
    call = call
  )
}

# Get a stanfit object that can be used to evaluate the log density of a model.
# The pointer to the compiled model is lost when a stanfit is saved, and
# cmdstanr models never have one, so in those cases we create an empty stanfit.
rstan_log_density <- function(x) {
  is_rstan <- S7::S7_inherits(x@backend, rstan)
  if (is_rstan && valid_stanfit(x@model)) {
    return(x@model)
  }

  compiled_model <- if (is_rstan) {
    x@model@stanmodel
  } else {
    stan_model(rstan(), code = x@stancode)
  }

  out <- utils::capture.output( # nolint
    log_density <- suppressMessages(
      rstan::sampling(
        compiled_model,
        data = estimation_data(x),
        chains = 0,
        refresh = 0
      )
    )
  )
  log_density
}

# Recreate the data list used to estimate the model. The `stan_data()` method
# for measrdcm objects only includes the data needed for generated quantities,
# not the model-specific elements (e.g., `Xi` for the DINA and DINO models).
estimation_data <- function(x) {
  item_names <- names(x@data$item_names)
  resp_names <- names(x@data$respondent_names)

  wide_data <- matrix(
    NA_integer_,
    nrow = length(resp_names),
    ncol = length(item_names),
    dimnames = list(NULL, item_names)
  )
  clean_data <- x@data$clean_data
  wide_data[cbind(
    as.integer(clean_data$resp_id),
    as.integer(clean_data$item_id)
  )] <- clean_data$score

  dcmstan::stan_data(
    x@model_spec,
    data = tibble::as_tibble(wide_data),
    missing = NA
  )
}

valid_stanfit <- function(x) {
  tryCatch(
    {
      rstan::get_num_upars(x)
      TRUE
    },
    error = function(e) FALSE
  )
}

eval_log_density <- function(s_row, data) {
  out <- tryCatch(rstan::log_prob(data, s_row), error = function(e) -Inf)
  if (is.na(out)) -Inf else out
}

# Transform posterior draws to the unconstrained parameter space. Draws that are
# read from csv files (i.e., everything except MCMC with rstan) are rounded, so
# they may not satisfy the parameter constraints that are verified by Stan.
unconstrain_draws <- function(x, log_density) {
  pars <- setdiff(log_density@model_pars, c("log_Vc", "pi", "lp__"))
  dims <- log_density@par_dims[pars]

  draws <- get_draws(x, vars = pars)
  if (posterior::ndraws(draws) == 0) {
    cli::cli_abort(
      c(
        "The marginal likelihood could not be calculated.",
        x = "The estimated model does not contain any posterior draws.",
        i = paste(
          "Check the estimation of the model, or consider using",
          "{.code method = \"mcmc\"}."
        )
      ),
      call = rlang::caller_env()
    )
  }

  draws <- draws |>
    posterior::merge_chains() |>
    posterior::as_draws_rvars() |>
    lapply(\(par) {
      par <- posterior::draws_of(par)
      matrix(par, nrow = nrow(par))
    })
  draws <- draws[pars]

  if ("Vc" %in% pars) {
    draws$Vc <- draws$Vc / rowSums(draws$Vc)
  }

  num_draws <- nrow(draws[[1]])
  num_upars <- rstan::get_num_upars(log_density)
  upars <- vapply(
    seq_len(num_draws),
    \(i) {
      theta <- mapply(
        \(par, dim) if (length(dim)) array(par[i, ], dim = dim) else par[i, ],
        draws,
        dims,
        SIMPLIFY = FALSE
      )
      tryCatch(
        rstan::unconstrain_pars(log_density, theta),
        error = function(e) rep(NA_real_, num_upars)
      )
    },
    numeric(num_upars)
  )
  upars <- matrix(upars, ncol = num_upars, byrow = TRUE)
  colnames(upars) <- paste0("x", seq_len(num_upars))

  keep <- apply(is.finite(upars), 1, all)
  num_drop <- sum(!keep)
  if (num_drop > num_draws / 2) {
    cli::cli_abort(
      c(
        "The marginal likelihood could not be calculated.",
        x = paste(
          "{num_drop} of {num_draws} posterior draws {?is/are} not {?a/} valid",
          "{cli::qty(num_drop)} set{?s} of parameter values."
        ),
        i = paste(
          "Check the estimation of the model, or consider using",
          "{.code method = \"mcmc\"}."
        )
      ),
      call = rlang::caller_env()
    )
  } else if (num_drop > 0) {
    cli::cli_warn(
      paste(
        "{num_drop} of {num_draws} posterior draws {cli::qty(num_drop)}",
        "{?was/were} excluded from the marginal likelihood calculation because",
        "of invalid parameter values."
      ),
      call = rlang::caller_env()
    )
  }

  upars[keep, , drop = FALSE]
}

#' Bayes factor for model comparisons
#'
#' @description
#' Calculate the Bayes factor for model comparisons, which represents the
#' posterior odds of the null hypothesis when the prior probability of the null
#' model is 0.5 (Jeffreys, 1935; Kass & Raftery, 1995).
#' Consistent with the Bayesian reporting guidelines from Kruschke (2021), we
#' calculate the posterior probability of the null model for a variety of prior
#' probabilities, in addition to the Bayes factor.
#'
#' # Methods
#' `bayes_factor()` is an S7 generic with methods available for the following
#' classes:
#'
#' `r doclisting::methods_list("bayes_factor")`
#'
#' @param x A [measrdcm][dcm_estimate()] object.
#' @param ... Additional [measrdcm][dcm_estimate()] to be compared to `x`.
#' @param model_names Names given to each provided model in the comparison
#'   output. If `NULL` (the default), the names will be parsed from the names of
#'   the objects passed for comparison.
#' @param prior_prob A numeric vector of prior probabilities for the null model
#'   used to calculate the posterior probability of the null model relative to
#'   alternative model. See details for more information.
#'
#' @details
#' Bayes factors will be calculated for all possible pairwise comparisons
#' between the models provided to `x` and `...`. In each comparison, one model
#' is identified as the null model, and the other is the alternative. This
#' distinction is not terribly meaningful from a calculation standpoint, as the
#' probabilities for the alternative model are simply 1 minus the null
#' probabilities. If you want particular models to be labeled as the "null", the
#' determination is made by the order the models are sent to the function. That
#' is, `x` will always be the null model. The first model included in `...` will
#' be the alternative model when compared to `x` and the null model when
#' compared to all other models included in `...`. Similarly, the second model
#' included in `...` will be the alternative model when compared to `x` and the
#' first model included in `...` and the null model in all other comparisons.
#'
#' `prior_prob` is used to specify a vector of possible prior probabilities for
#' the null model. These are used in conjunction with the Bayes factor to
#' determine the posterior model probability for the null model, relative to the
#' alternative model. The posterior probability for the alternative model can
#' be calculated as 1 minus the null model's posterior probability. You may
#' specify a specific prior probability, or specify a range of possibilities to
#' construct a graph similar to Kruschke's (2021) Figure 1. These probabilities
#' can be interpreted as, "If the prior probability is \{`prior_prob_null`\},
#' then the posterior is \{`posterior_prob_null`\}" (or 1 minus for the
#' alternative model).
#'
#' @concept Bayes
#'
#' @return A [tibble][tibble::tibble-package] with one row per model comparison
#'   and four columns.
#'   * `null_model`: The null model in the comparison.
#'   * `alt_model`: The alternative model in the comparison.
#'   * `bf`: The estimated Bayes factor.
#'   * `posterior_probs`: A nested list column, where element element is a
#'     tibble with two columns:
#'     * `prior_prob_null`: The prior probability that the null model is
#'       correct.
#'     * `posterior_prob_null`: The posterior probability that the null model is
#'       correct.
#'
#'     The list column can be unnested with [tidyr::unnest()] (see examples). If
#'     `prior_prob` is `NULL`, the `posterior_probs` column is excluded from
#'     the returned object.
#' @export
#'
#' @references Jeffreys, H. (1935). Some tests of significance, treated by the
#'   theory of probability. *Mathematical Proceedings of the Cambridge
#'   Philosophical Society, 31*(2), 203-222. \doi{10.1017/S030500410001330X}
#' @references Kass, R. E., & Raftery, A. E. (1995). Bayes factors.
#'   *Journal of the American Statistical Association, 90*(430), 773-795.
#'   \doi{10.1080/01621459.1995.10476572}
#' @references Kruschke, J. K. (2021). Bayesian analysis reporting guidelines.
#'   *Nature, 5*, 1282-1291. \doi{10.1038/s41562-021-01177-7}
#'
#' @examplesIf measr_examples()
#' mdm_dina <- dcm_estimate(
#'   dcm_specify(
#'     qmatrix = dcmdata::mdm_qmatrix,
#'     identifier = "item",
#'     measurement_model = dina()
#'   ),
#'   data = dcmdata::mdm_data,
#'   missing = NA,
#'   identifier = "respondent",
#'   method = "mcmc",
#'   seed = 63277,
#'   backend = "rstan",
#'   iter = 700,
#'   warmup = 500,
#'   chains = 2,
#'   refresh = 0
#' )
#'
#' mdm_dino <- dcm_estimate(
#'   dcm_specify(
#'     qmatrix = dcmdata::mdm_qmatrix,
#'     identifier = "item",
#'     measurement_model = dino()
#'   ),
#'   data = dcmdata::mdm_data,
#'   missing = NA,
#'   identifier = "respondent",
#'   method = "mcmc",
#'   seed = 63277,
#'   backend = "rstan",
#'   iter = 700,
#'   warmup = 500,
#'   chains = 2,
#'   refresh = 0
#' )
#'
#' bf <- bayes_factor(mdm_dina, mdm_dino)
#' bf
#'
#' tidyr::unnest(bf, "posterior_probs")
bayes_factor <- S7::new_generic(
  "bayes_factor",
  "x",
  function(x, ..., model_names = NULL, prior_prob = seq(.02, .98, by = .02)) {
    for (i in seq_along(prior_prob)) {
      check_number_decimal(prior_prob[i], min = 0, max = 1, arg = "prior_prob")
    }

    S7::S7_dispatch()
  }
)

S7::method(bayes_factor, measrdcm) <- function(
  x,
  ...,
  model_names = NULL,
  prior_prob = seq(.02, .98, by = .02)
) {
  dots <- rlang::dots_list(..., .named = TRUE)
  dots_check <- vapply(dots, S7::S7_inherits, logical(1), class = measrdcm)
  if (!all(dots_check)) {
    msg <- paste(
      "{.arg {cli::cli_vec(names(dots)[!dots_check])}} must",
      "{?be a/be a/all be} {.cls measrdcm} object{?s}"
    )
    cli::cli_abort(msg)
  }
  all_models <- c(list(x), dots)

  if (is.null(model_names)) {
    model_names <- c(rlang::caller_arg(x), names(dots))
  } else if (length(model_names) != length(all_models)) {
    rdcmchecks::abort_bad_argument(
      arg = "model_names",
      must = glue::glue(
        "be of length {length(all_models)}, ",
        "the same as the number of models provided"
      ),
      not = length(model_names)
    )
  }

  for (i in seq_along(all_models)) {
    check_log_mll(all_models[[i]], arg = model_names[i])
  }
  mll <- vapply(all_models, log_mll, double(1), USE.NAMES = FALSE)

  pairs <- combn(seq_along(all_models), m = 2)
  null_mll <- mll[pairs[1, ]]
  alt_mll <- mll[pairs[2, ]]

  bf <- tibble::tibble(
    null_model = model_names[pairs[1, ]],
    alt_model = model_names[pairs[2, ]],
    bf = exp(null_mll - alt_mll)
  )

  if (!is.null(prior_prob)) {
    bf$posterior_probs <- mapply(
      calc_model_probabilities,
      null_mll,
      alt_mll,
      MoreArgs = list(prior_prob = prior_prob),
      SIMPLIFY = FALSE,
      USE.NAMES = FALSE
    )
  }

  bf
}

calc_model_probabilities <- function(null_mll, alt_mll, prior_prob) {
  tibble::tibble(
    prior_prob_null = prior_prob,
    posterior_prob_null = stats::plogis(
      null_mll - alt_mll + stats::qlogis(prior_prob)
    )
  )
}
