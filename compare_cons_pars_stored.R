# ============================================================================
# COMPARE CONSERVATIVE VS PARSIMONIOUS SOLUTIONS - STORED RESULTS VERSION
# ============================================================================
# This script stores all results in a structured list for easy inspection

library(QCA)
library(dplyr)
library(readr)

# Load data
data <- read_csv("fcdo_qca_rich_binary.csv", show_col_types = FALSE)
data <- as.data.frame(data)

# Define conditions
all_conditions <- c(
  "StrategicAgendaClarity", "SharedGovernance", "FundingFlexibility", "SelectionProcedures",
  "OutputsAccessible", "OutputsCapacity", "LocalEmbedded", "ImpactStrategy",
  "PartnershipEquity", "EquityLocalisation", "EquityGESI",
  "FundingLongevity_ADAPTED", "InstabilityResponse", "MEL_STRENGTHENED"
)

# Define outcome parameters
outcome_params <- list(
  HIGH_PERFORMANCE = list(n_cut = 2, incl_cut = 0.85),
  IMPACT_ACHIEVEMENT = list(n_cut = 3, incl_cut = 0.85),
  SUSTAINABILITY = list(n_cut = 3, incl_cut = 0.85),
  EQUITY_OUTCOMES = list(n_cut = 2, incl_cut = 0.85)
)

# ============================================================================
# MAIN RESULTS STORAGE OBJECT
# ============================================================================
# This will hold all results for easy inspection
qca_results <- list()

for (outcome_var in names(outcome_params)) {
  params <- outcome_params[[outcome_var]]
  
  cat("\n================================================================================\n")
  cat("Processing:", outcome_var, "\n")
  cat("================================================================================\n")
  
  # Initialize result storage for this outcome
  qca_results[[outcome_var]] <- list(
    outcome = outcome_var,
    n_cut = params$n_cut,
    incl_cut = params$incl_cut,
    prevalence = sum(data[[outcome_var]] == 1),
    prevalence_pct = round(mean(data[[outcome_var]] == 1) * 100, 1),
    truth_table = NULL,
    n_sufficient_configs = 0,
    conservative = list(
      solution = NULL,
      pathways = NULL,
      consistency = NA,
      coverage = NA
    ),
    parsimonious = list(
      solution = NULL,
      pathways = NULL,
      consistency = NA,
      coverage = NA
    )
  )
  
  # Create truth table
  tt <- truthTable(data, outcome_var, all_conditions, 
                   incl.cut = params$incl_cut, n.cut = params$n_cut)
  qca_results[[outcome_var]]$truth_table <- tt
  
  # Count sufficient configurations
  n_suff <- sum(tt$tt$OUT == 1, na.rm = TRUE)
  qca_results[[outcome_var]]$n_sufficient_configs <- n_suff
  
  if (n_suff == 0) {
    cat(">>> NO SUFFICIENT CONFIGURATIONS <<<\n")
    next
  }
  
  # =====================
  # CONSERVATIVE SOLUTION
  # =====================
  sol_cons <- tryCatch({
    minimize(tt, details = TRUE, include = "")
  }, error = function(e) {
    cat("Conservative ERROR:", e$message, "\n")
    NULL
  })
  
  if (!is.null(sol_cons)) {
    qca_results[[outcome_var]]$conservative$solution <- sol_cons
    qca_results[[outcome_var]]$conservative$pathways <- sol_cons$solution[[1]]
    
    # Extract metrics
    tryCatch({
      ic <- sol_cons$IC
      if (length(sol_cons$solution) == 1) {
        sic <- ic$sol.incl.cov
        if (is.matrix(sic) || is.data.frame(sic)) {
          qca_results[[outcome_var]]$conservative$consistency <- round(sic[nrow(sic), "inclS"], 3)
          qca_results[[outcome_var]]$conservative$coverage <- round(sic[nrow(sic), "covS"] * 100, 1)
        }
      } else {
        sic <- ic[[1]]$sol.incl.cov
        if (is.matrix(sic) || is.data.frame(sic)) {
          qca_results[[outcome_var]]$conservative$consistency <- round(sic[nrow(sic), "inclS"], 3)
          qca_results[[outcome_var]]$conservative$coverage <- round(sic[nrow(sic), "covS"] * 100, 1)
        }
      }
    }, error = function(e) NULL)
  }
  
  # =====================
  # PARSIMONIOUS SOLUTION
  # =====================
  sol_pars <- tryCatch({
    minimize(tt, details = TRUE, include = "?")
  }, error = function(e) {
    cat("Parsimonious ERROR:", e$message, "\n")
    NULL
  })
  
  if (!is.null(sol_pars)) {
    qca_results[[outcome_var]]$parsimonious$solution <- sol_pars
    qca_results[[outcome_var]]$parsimonious$pathways <- sol_pars$solution[[1]]
    
    # Extract metrics
    tryCatch({
      ic <- sol_pars$IC
      if (length(sol_pars$solution) == 1) {
        sic <- ic$sol.incl.cov
        if (is.matrix(sic) || is.data.frame(sic)) {
          qca_results[[outcome_var]]$parsimonious$consistency <- round(sic[nrow(sic), "inclS"], 3)
          qca_results[[outcome_var]]$parsimonious$coverage <- round(sic[nrow(sic), "covS"] * 100, 1)
        }
      } else {
        sic <- ic[[1]]$sol.incl.cov
        if (is.matrix(sic) || is.data.frame(sic)) {
          qca_results[[outcome_var]]$parsimonious$consistency <- round(sic[nrow(sic), "inclS"], 3)
          qca_results[[outcome_var]]$parsimonious$coverage <- round(sic[nrow(sic), "covS"] * 100, 1)
        }
      }
    }, error = function(e) NULL)
  }
}

# ============================================================================
# SUMMARY FUNCTIONS
# ============================================================================

# Function to print a nice summary
print_summary <- function() {
  cat("\n")
  cat("================================================================================\n")
  cat("                         QCA RESULTS SUMMARY                                    \n")
  cat("================================================================================\n\n")
  
  for (outcome in names(qca_results)) {
    res <- qca_results[[outcome]]
    cat("--------------------------------------------------------------------------------\n")
    cat(outcome, "\n")
    cat("--------------------------------------------------------------------------------\n")
    cat("  Prevalence:", res$prevalence, "/", nrow(data), "(", res$prevalence_pct, "%)\n")
    cat("  Parameters: n.cut =", res$n_cut, ", incl.cut =", res$incl_cut, "\n")
    cat("  Sufficient configurations:", res$n_sufficient_configs, "\n")
    cat("\n")
    
    cat("  PARSIMONIOUS SOLUTION:\n")
    if (!is.null(res$parsimonious$pathways)) {
      cat("    Consistency:", res$parsimonious$consistency, "\n")
      cat("    Coverage:", res$parsimonious$coverage, "%\n")
      cat("    Pathways:\n")
      for (i in seq_along(res$parsimonious$pathways)) {
        cat("      P", i, ": ", res$parsimonious$pathways[i], "\n", sep = "")
      }
    } else {
      cat("    No solution found\n")
    }
    cat("\n")
    
    cat("  CONSERVATIVE SOLUTION:\n")
    if (!is.null(res$conservative$pathways)) {
      cat("    Consistency:", res$conservative$consistency, "\n")
      cat("    Coverage:", res$conservative$coverage, "%\n")
      cat("    Pathways:", length(res$conservative$pathways), "pathways\n")
    } else {
      cat("    No solution found\n")
    }
    cat("\n")
  }
}

# Function to get pathways as a data frame
get_pathways_df <- function() {
  rows <- list()
  for (outcome in names(qca_results)) {
    res <- qca_results[[outcome]]
    if (!is.null(res$parsimonious$pathways)) {
      for (i in seq_along(res$parsimonious$pathways)) {
        rows[[length(rows) + 1]] <- data.frame(
          Outcome = outcome,
          Solution = "Parsimonious",
          Pathway_Num = i,
          Pathway = res$parsimonious$pathways[i],
          Consistency = res$parsimonious$consistency,
          Coverage = res$parsimonious$coverage,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  do.call(rbind, rows)
}

# ============================================================================
# PRINT SUMMARY AND SAVE
# ============================================================================

print_summary()

# Create pathway summary data frame
pathways_df <- get_pathways_df()
cat("\n\nPARSIMONIOUS PATHWAYS DATA FRAME:\n")
print(pathways_df)

# Save workspace for later inspection
save(qca_results, pathways_df, data, all_conditions, outcome_params, 
     file = "qca_results_stored.RData")
cat("\n\nResults saved to: qca_results_stored.RData\n")

# ============================================================================
# HOW TO INSPECT RESULTS
# ============================================================================
cat("\n")
cat("================================================================================\n")
cat("HOW TO INSPECT RESULTS:\n")
cat("================================================================================\n")
cat("\n")
cat("# View all results:\n")
cat("  qca_results\n")
cat("\n")
cat("# View specific outcome:\n")
cat("  qca_results$IMPACT_ACHIEVEMENT\n")
cat("  qca_results$SUSTAINABILITY\n")
cat("  qca_results$EQUITY_OUTCOMES\n")
cat("  qca_results$HIGH_PERFORMANCE\n")
cat("\n")
cat("# View parsimonious pathways for an outcome:\n")
cat("  qca_results$IMPACT_ACHIEVEMENT$parsimonious$pathways\n")
cat("\n")
cat("# View full solution object (for detailed QCA output):\n")
cat("  qca_results$IMPACT_ACHIEVEMENT$parsimonious$solution\n")
cat("\n")
cat("# View truth table:\n")
cat("  qca_results$IMPACT_ACHIEVEMENT$truth_table\n")
cat("\n")
cat("# View pathways as data frame:\n")
cat("  pathways_df\n")
cat("\n")
cat("# Reload saved results later:\n")
cat("  load('qca_results_stored.RData')\n")
cat("\n")
