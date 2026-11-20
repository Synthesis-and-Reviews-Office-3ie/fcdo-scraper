# ============================================================================
# COMPARE CONSERVATIVE VS PARSIMONIOUS SOLUTIONS
# ============================================================================

library(QCA)
library(dplyr)
library(readr)

data <- read_csv("fcdo_qca_rich_binary.csv", show_col_types = FALSE)
data <- as.data.frame(data)

all_conditions <- c(
  "StrategicAgendaClarity", "SharedGovernance", "FundingFlexibility", "SelectionProcedures",
  "OutputsAccessible", "OutputsCapacity", "LocalEmbedded", "ImpactStrategy",
  "PartnershipEquity", "EquityLocalisation", "EquityGESI",
  "FundingLongevity_ADAPTED", "InstabilityResponse", "MEL_STRENGTHENED"
)

outcomes <- list(
  HIGH_PERFORMANCE = list(n_cut = 2, incl_cut = 0.85),
  IMPACT_ACHIEVEMENT = list(n_cut = 3, incl_cut = 0.85),
  SUSTAINABILITY = list(n_cut = 3, incl_cut = 0.85),
  EQUITY_OUTCOMES = list(n_cut = 2, incl_cut = 0.85)
)

for (outcome_var in names(outcomes)) {
  params <- outcomes[[outcome_var]]
  
  cat("\n\n")
  cat("################################################################################\n")
  cat("OUTCOME:", outcome_var, "\n")
  cat("################################################################################\n\n")
  
  tt <- truthTable(data, outcome_var, all_conditions, 
                   incl.cut = params$incl_cut, n.cut = params$n_cut)
  
  n_suff <- sum(tt$tt$OUT == 1, na.rm = TRUE)
  if (n_suff == 0) {
    cat(">>> NO SUFFICIENT CONFIGURATIONS <<<\n")
    next
  }
  
  # =====================
  # CONSERVATIVE SOLUTION (include = "")
  # =====================
  cat("=== CONSERVATIVE SOLUTION (include='') ===\n")
  sol_cons <- tryCatch({
    minimize(tt, details = TRUE, include = "")
  }, error = function(e) {
    cat("ERROR:", e$message, "\n")
    NULL
  })
  
  if (!is.null(sol_cons)) {
    cat("Pathways:\n")
    for (i in seq_along(sol_cons$solution[[1]])) {
      cat("  ", i, ":", sol_cons$solution[[1]][i], "\n")
    }
    # Try to get metrics
    tryCatch({
      ic <- sol_cons$IC
      if (length(sol_cons$solution) == 1) {
        sic <- ic$sol.incl.cov
        if (is.matrix(sic) || is.data.frame(sic)) {
          cat("Consistency:", round(sic[nrow(sic), "inclS"], 3), "\n")
          cat("Coverage:", round(sic[nrow(sic), "covS"] * 100, 1), "%\n")
        }
      } else {
        sic <- ic[[1]]$sol.incl.cov
        if (is.matrix(sic) || is.data.frame(sic)) {
          cat("Model 1 Consistency:", round(sic[nrow(sic), "inclS"], 3), "\n")
          cat("Model 1 Coverage:", round(sic[nrow(sic), "covS"] * 100, 1), "%\n")
        }
      }
    }, error = function(e) cat("Could not extract metrics\n"))
  }
  
  cat("\n")
  
  # =====================
  # PARSIMONIOUS SOLUTION (include = "?")
  # =====================
  cat("=== PARSIMONIOUS SOLUTION (include='?') ===\n")
  sol_pars <- tryCatch({
    minimize(tt, details = TRUE, include = "?")
  }, error = function(e) {
    cat("ERROR:", e$message, "\n")
    NULL
  })
  
  if (!is.null(sol_pars)) {
    cat("Pathways:\n")
    for (i in seq_along(sol_pars$solution[[1]])) {
      cat("  ", i, ":", sol_pars$solution[[1]][i], "\n")
    }
    # Try to get metrics
    tryCatch({
      ic <- sol_pars$IC
      if (length(sol_pars$solution) == 1) {
        sic <- ic$sol.incl.cov
        if (is.matrix(sic) || is.data.frame(sic)) {
          cat("Consistency:", round(sic[nrow(sic), "inclS"], 3), "\n")
          cat("Coverage:", round(sic[nrow(sic), "covS"] * 100, 1), "%\n")
        }
      } else {
        sic <- ic[[1]]$sol.incl.cov
        if (is.matrix(sic) || is.data.frame(sic)) {
          cat("Model 1 Consistency:", round(sic[nrow(sic), "inclS"], 3), "\n")
          cat("Model 1 Coverage:", round(sic[nrow(sic), "covS"] * 100, 1), "%\n")
        }
      }
    }, error = function(e) cat("Could not extract metrics\n"))
  }
}

cat("\n\n================================================================================\n")
cat("COMPARISON COMPLETE\n")
cat("================================================================================\n")
