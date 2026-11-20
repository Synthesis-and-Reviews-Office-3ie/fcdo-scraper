# =============================================================================
# FCDO QCA Enhanced Standard Analysis (ESA) - Full Workflow
# =============================================================================
# This script implements the complete ESA methodology:
# 1. Necessity Analysis (superSubset)
# 2. Sufficiency Analysis with Truth Table
# 3. Contradiction Analysis (findRows)
# 4. Conservative Solution (no remainders)
# 5. Enhanced Solution (excluding contradictory remainders)
# 6. Parsimonious Solution (all remainders as don't cares)
# 7. Intermediate Solution (with directional expectations)
# =============================================================================

library(QCA)

# Load data
data <- read.csv("fcdo_qca_rich_binary.csv")

# Convert all binary columns to integer (fixes superSubset INTEGER error)
# The QCA package expects integer type for crisp-set data
binary_cols <- c("StrategicAgendaClarity", "SharedGovernance", "FundingFlexibility",
                 "SelectionProcedures", "OutputsAccessible", "OutputsCapacity",
                 "LocalEmbedded", "ImpactStrategy", "PartnershipEquity",
                 "EquityLocalisation", "EquityGESI", "FundingLongevity_ADAPTED",
                 "InstabilityResponse", "MEL_STRENGTHENED",
                 "HIGH_PERFORMANCE", "IMPACT_ACHIEVEMENT", "SUSTAINABILITY", "EQUITY_OUTCOMES")

for (col in binary_cols) {
  if (col %in% names(data)) {
    data[[col]] <- as.integer(data[[col]])
  }
}

# Define conditions
conditions <- c("StrategicAgendaClarity", "SharedGovernance", "FundingFlexibility",
                "SelectionProcedures", "OutputsAccessible", "OutputsCapacity",
                "LocalEmbedded", "ImpactStrategy", "PartnershipEquity",
                "EquityLocalisation", "EquityGESI", "FundingLongevity_ADAPTED",
                "InstabilityResponse", "MEL_STRENGTHENED")

# Define outcomes with their adaptive thresholds
# Rare outcomes (< 20% or < 35%): n.cut = 2
# Common outcomes (> 50%): n.cut = 3
outcomes <- list(
  HIGH_PERFORMANCE = list(n.cut = 2, expected_rare = TRUE),
  IMPACT_ACHIEVEMENT = list(n.cut = 3, expected_rare = FALSE),
  SUSTAINABILITY = list(n.cut = 3, expected_rare = FALSE),
  EQUITY_OUTCOMES = list(n.cut = 2, expected_rare = TRUE)
)

# Common parameters
incl.cut <- 0.85  # Inclusion threshold for sufficiency
pri.cut <- 0.5    # PRI threshold (Proportional Reduction in Inconsistency)
nec.cut <- 0.9    # Necessity threshold

# Define directional expectations for intermediate solution
# Based on theoretical expectations: which conditions, when PRESENT, 
# should contribute to the outcome?
# 1 = presence expected to contribute
# 0 = absence expected to contribute
# NA or not listed = no expectation (use for ambiguous cases)

dir_exp <- list(
  HIGH_PERFORMANCE = c(
    StrategicAgendaClarity = 1,
    SharedGovernance = 1,
    FundingFlexibility = 1,
    SelectionProcedures = 1,
    OutputsAccessible = 1,
    OutputsCapacity = 1,
    LocalEmbedded = 1,
    ImpactStrategy = 1,
    PartnershipEquity = 1,
    EquityLocalisation = 1,
    EquityGESI = 1,
    FundingLongevity_ADAPTED = 1,
    InstabilityResponse = 1,
    MEL_STRENGTHENED = 1
  ),
  IMPACT_ACHIEVEMENT = c(
    StrategicAgendaClarity = 1,
    SharedGovernance = 1,
    FundingFlexibility = 1,
    SelectionProcedures = 1,
    OutputsAccessible = 1,
    OutputsCapacity = 1,
    LocalEmbedded = 1,
    ImpactStrategy = 1,
    PartnershipEquity = 1,
    EquityLocalisation = 1,
    EquityGESI = 1,
    FundingLongevity_ADAPTED = 1,
    InstabilityResponse = 1,
    MEL_STRENGTHENED = 1
  ),
  SUSTAINABILITY = c(
    StrategicAgendaClarity = 1,
    SharedGovernance = 1,
    FundingFlexibility = 1,
    SelectionProcedures = 1,
    OutputsAccessible = 1,
    OutputsCapacity = 1,
    LocalEmbedded = 1,
    ImpactStrategy = 1,
    PartnershipEquity = 1,
    EquityLocalisation = 1,
    EquityGESI = 1,
    FundingLongevity_ADAPTED = 1,  # Especially important for sustainability
    InstabilityResponse = 1,
    MEL_STRENGTHENED = 1
  ),
  EQUITY_OUTCOMES = c(
    StrategicAgendaClarity = 1,
    SharedGovernance = 1,
    FundingFlexibility = 1,
    SelectionProcedures = 1,
    OutputsAccessible = 1,
    OutputsCapacity = 1,
    LocalEmbedded = 1,
    ImpactStrategy = 1,
    PartnershipEquity = 1,
    EquityLocalisation = 1,
    EquityGESI = 1,        # Core for equity
    FundingLongevity_ADAPTED = 1,
    InstabilityResponse = 1,
    MEL_STRENGTHENED = 1
  )
)

# Storage for all results
esa_results <- list()

# =============================================================================
# HELPER FUNCTION: Extract solution metrics safely
# =============================================================================

get_solution_metrics <- function(sol) {
  # Returns list with consistency and coverage, handling different QCA versions
  if (is.null(sol)) return(list(cons = NA, cov = NA))
  
  cons <- NA
  cov <- NA
  
  tryCatch({
    if (!is.null(sol$IC)) {
      # Method 1: Direct sol.incl.cov (single solution, no ambiguity)
      if (!is.null(sol$IC$sol.incl.cov)) {
        sol_metrics <- sol$IC$sol.incl.cov
        if ("inclS" %in% names(sol_metrics)) {
          cons <- sol_metrics$inclS[1]
        }
        if ("covS" %in% names(sol_metrics)) {
          cov <- sol_metrics$covS[1]
        }
      }
      
      # Method 2: Via $overall$sol.incl.cov (multiple solutions / model ambiguity)
      if (is.na(cons) && !is.null(sol$IC$overall) && !is.null(sol$IC$overall$sol.incl.cov)) {
        sol_metrics <- sol$IC$overall$sol.incl.cov
        if ("inclS" %in% names(sol_metrics)) {
          cons <- sol_metrics$inclS[1]
        }
        if ("covS" %in% names(sol_metrics)) {
          cov <- sol_metrics$covS[1]
        }
      }
      
      # Method 3: Fallback to individual solutions (M1)
      if (is.na(cons) && !is.null(sol$IC$individual) && length(sol$IC$individual) > 0) {
        ind_sol <- sol$IC$individual[[1]]
        if (!is.null(ind_sol$sol.incl.cov)) {
          if ("inclS" %in% names(ind_sol$sol.incl.cov)) {
            cons <- ind_sol$sol.incl.cov$inclS[1]
          }
          if ("covS" %in% names(ind_sol$sol.incl.cov)) {
            cov <- ind_sol$sol.incl.cov$covS[1]
          }
        }
      }
    }
  }, error = function(e) {
    # Silently fail - metrics will be NA
  })
  
  return(list(cons = as.numeric(cons), cov = as.numeric(cov)))
}

# =============================================================================
# ANALYSIS FUNCTION: Full ESA Workflow
# =============================================================================

run_esa_analysis <- function(outcome_name, outcome_params, data, conditions) {
  
  cat("\n")
  cat("=============================================================================\n")
  cat(paste("ESA ANALYSIS FOR:", outcome_name, "\n"))
  cat("=============================================================================\n\n")
  
  result <- list()
  result$outcome <- outcome_name
  result$parameters <- outcome_params
  
  # Store n.cut locally to avoid scoping issues
  n_cut <- outcome_params$n.cut
  
  # -------------------------------------------------------------------------
  # STEP 0: Descriptive Statistics
  # -------------------------------------------------------------------------
  cat("STEP 0: DESCRIPTIVE STATISTICS\n")
  cat("-------------------------------\n")
  
  outcome_values <- data[[outcome_name]]
  n_total <- length(outcome_values)
  n_positive <- sum(outcome_values == 1, na.rm = TRUE)
  n_negative <- sum(outcome_values == 0, na.rm = TRUE)
  n_missing <- sum(is.na(outcome_values))
  
  cat(paste("Total cases:", n_total, "\n"))
  cat(paste("Positive outcome (1):", n_positive, "(", round(100*n_positive/n_total, 1), "%)\n"))
  cat(paste("Negative outcome (0):", n_negative, "(", round(100*n_negative/n_total, 1), "%)\n"))
  if(n_missing > 0) cat(paste("Missing:", n_missing, "\n"))
  cat(paste("Frequency threshold (n.cut):", n_cut, "\n\n"))
  
  result$descriptives <- list(
    n_total = n_total,
    n_positive = n_positive,
    n_negative = n_negative,
    prevalence = n_positive / n_total
  )
  
  # -------------------------------------------------------------------------
  # STEP 1: NECESSITY ANALYSIS
  # -------------------------------------------------------------------------
  cat("STEP 1: NECESSITY ANALYSIS (superSubset)\n")
  cat("-----------------------------------------\n")
  
  # Check necessity for single conditions (both presence and absence)
  necessity <- tryCatch({
    superSubset(data, 
                outcome = outcome_name, 
                conditions = conditions,
                relation = "necessity",
                incl.cut = nec.cut)
  }, error = function(e) {
    cat(paste("Error in necessity analysis:", e$message, "\n"))
    NULL
  })
  
  if (!is.null(necessity)) {
    cat("\nNecessary conditions (consistency >= 0.90):\n")
    print(necessity)
    result$necessity <- necessity
  } else {
    cat("No conditions meet necessity threshold.\n")
    result$necessity <- NULL
  }
  
  # Also check SUIN conditions (Sufficient but Unnecessary part of 
  # a factor that is Insufficient but Necessary for the outcome)
  # This checks if combinations are necessary
  cat("\nChecking for SUIN conditions (necessary disjunctions):\n")
  suin_check <- tryCatch({
    superSubset(data,
                outcome = outcome_name,
                conditions = conditions,
                relation = "necessity",
                incl.cut = nec.cut,
                depth = 2)  # Check combinations up to depth 2
  }, error = function(e) {
    cat(paste("Note:", e$message, "\n"))
    NULL
  })
  
  if (!is.null(suin_check)) {
    tryCatch(print(suin_check), error = function(e) cat("(SUIN results too complex to print - stored in results)\n"))
    result$suin <- suin_check
  } else {
    result$suin <- NULL
  }
  
  # -------------------------------------------------------------------------
  # STEP 2: TRUTH TABLE CONSTRUCTION
  # -------------------------------------------------------------------------
  cat("\n\nSTEP 2: TRUTH TABLE CONSTRUCTION\n")
  cat("---------------------------------\n")
  
  tt <- tryCatch({
    truthTable(data,
               outcome = outcome_name,
               conditions = conditions,
               incl.cut = incl.cut,
               n.cut = n_cut,
               complete = TRUE,  # Show all configurations including remainders
               show.cases = TRUE,
               sort.by = c("incl", "n"),
               decreasing = TRUE)
  }, error = function(e) {
    cat(paste("Error creating truth table:", e$message, "\n"))
    NULL
  })
  
  if (is.null(tt)) {
    cat("Could not create truth table. Skipping further analysis.\n")
    return(result)
  }
  
  result$truth_table <- tt
  
  # Truth table summary
  tt_df <- as.data.frame(tt$tt)
  n_configs_obs <- sum(tt_df$n > 0)
  n_configs_suff <- sum(tt_df$OUT == 1, na.rm = TRUE)
  n_configs_insuff <- sum(tt_df$OUT == 0, na.rm = TRUE)
  n_configs_remainder <- sum(tt_df$OUT == "?", na.rm = TRUE)
  
  cat(paste("Total possible configurations: 2^14 =", 2^14, "\n"))
  cat(paste("Observed configurations:", n_configs_obs, "\n"))
  cat(paste("Sufficient configurations (OUT=1):", n_configs_suff, "\n"))
  cat(paste("Insufficient configurations (OUT=0):", n_configs_insuff, "\n"))
  cat(paste("Logical remainders:", n_configs_remainder, "\n"))
  
  result$tt_summary <- list(
    observed = n_configs_obs,
    sufficient = n_configs_suff,
    insufficient = n_configs_insuff,
    remainders = n_configs_remainder
  )
  
  # -------------------------------------------------------------------------
  # STEP 3: FIND CONTRADICTORY CONFIGURATIONS
  # -------------------------------------------------------------------------
  cat("\n\nSTEP 3: CONTRADICTORY CONFIGURATIONS (findRows)\n")
  cat("-------------------------------------------------\n")
  
  # Contradictions: configurations with mixed outcomes (some cases positive, some negative)
  # These are rows where incl < 1 but n >= n.cut
  contradictory_rows <- tryCatch({
    # Get configurations that have cases but are not fully consistent
    # Method: find rows where we have enough cases but consistency is between 0 and 1
    rows_with_cases <- which(tt_df$n >= n_cut)
    
    # Among those, find ones that are "contradictory" 
    # (neither fully consistent 1 nor fully inconsistent 0)
    # These are marked as OUT=0 but have some positive cases
    potentially_contradictory <- tt_df[rows_with_cases, ]
    potentially_contradictory <- potentially_contradictory[
      potentially_contradictory$incl > 0 & 
      potentially_contradictory$incl < incl.cut, ]
    
    if (nrow(potentially_contradictory) > 0) {
      cat("Contradictory configurations found:\n")
      print(potentially_contradictory[, c(conditions, "n", "incl", "OUT")])
      potentially_contradictory
    } else {
      cat("No contradictory configurations found.\n")
      NULL
    }
  }, error = function(e) {
    cat(paste("Error finding contradictions:", e$message, "\n"))
    NULL
  })
  
  result$contradictions <- contradictory_rows
  
  # Use findRows to identify specific row numbers for exclusion
  if (!is.null(contradictory_rows) && nrow(contradictory_rows) > 0) {
    exclude_rows <- as.numeric(rownames(contradictory_rows))
    cat(paste("\nRow numbers to exclude from enhanced solution:", 
              paste(exclude_rows, collapse = ", "), "\n"))
    result$exclude_rows <- exclude_rows
  } else {
    result$exclude_rows <- NULL
  }
  
  # -------------------------------------------------------------------------
  # STEP 4: CONSERVATIVE SOLUTION (Complex Solution)
  # -------------------------------------------------------------------------
  cat("\n\nSTEP 4: CONSERVATIVE SOLUTION\n")
  cat("------------------------------\n")
  cat("(Uses only observed sufficient configurations, no remainders)\n\n")
  
  sol_conservative <- tryCatch({
    minimize(tt, 
             include = "1",      # Only sufficient configurations
             details = TRUE,
             show.cases = TRUE)
  }, error = function(e) {
    cat(paste("Error:", e$message, "\n"))
    NULL
  })
  
  if (!is.null(sol_conservative)) {
    tryCatch(print(sol_conservative), error = function(e) cat("(Solution too complex to print - stored in results)\n"))
    result$conservative <- sol_conservative
    
    # Extract key metrics using helper function
    metrics <- get_solution_metrics(sol_conservative)
    if (!is.na(metrics$cons) || !is.na(metrics$cov)) {
      cat("\nConservative Solution Metrics:\n")
      cat(paste("  Overall consistency:", round(metrics$cons, 3), "\n"))
      cat(paste("  Overall coverage:", round(metrics$cov, 3), "\n"))
    }
  } else {
    cat("No conservative solution found (possibly no sufficient configurations).\n")
    result$conservative <- NULL
  }
  
  # -------------------------------------------------------------------------
  # STEP 5: ENHANCED SOLUTION
  # -------------------------------------------------------------------------
  cat("\n\nSTEP 5: ENHANCED SOLUTION\n")
  cat("--------------------------\n")
  cat("(Uses remainders BUT excludes contradictory ones)\n\n")
  
  if (!is.null(result$exclude_rows) && length(result$exclude_rows) > 0) {
    sol_enhanced <- tryCatch({
      minimize(tt,
               include = "?",           # Use remainders
               exclude = result$exclude_rows,  # But exclude contradictory
               details = TRUE,
               show.cases = TRUE)
    }, error = function(e) {
      cat(paste("Error:", e$message, "\n"))
      NULL
    })
  } else {
    # No contradictions to exclude - enhanced = parsimonious
    cat("No contradictory remainders found. Enhanced solution equals parsimonious.\n")
    sol_enhanced <- tryCatch({
      minimize(tt,
               include = "?",
               details = TRUE,
               show.cases = TRUE)
    }, error = function(e) {
      cat(paste("Error:", e$message, "\n"))
      NULL
    })
  }
  
  if (!is.null(sol_enhanced)) {
    tryCatch(print(sol_enhanced), error = function(e) cat("(Solution too complex to print - stored in results)\n"))
    result$enhanced <- sol_enhanced
  } else {
    result$enhanced <- NULL
  }
  
  # -------------------------------------------------------------------------
  # STEP 6: PARSIMONIOUS SOLUTION
  # -------------------------------------------------------------------------
  cat("\n\nSTEP 6: PARSIMONIOUS SOLUTION\n")
  cat("------------------------------\n")
  cat("(Uses ALL remainders as logical don't cares)\n\n")
  
  sol_parsimonious <- tryCatch({
    minimize(tt,
             include = "?",      # Use all remainders
             details = TRUE,
             show.cases = TRUE)
  }, error = function(e) {
    cat(paste("Error:", e$message, "\n"))
    NULL
  })
  
  if (!is.null(sol_parsimonious)) {
    tryCatch(print(sol_parsimonious), error = function(e) cat("(Solution too complex to print - stored in results)\n"))
    result$parsimonious <- sol_parsimonious
    
    metrics <- get_solution_metrics(sol_parsimonious)
    if (!is.na(metrics$cons) || !is.na(metrics$cov)) {
      cat("\nParsimonious Solution Metrics:\n")
      cat(paste("  Overall consistency:", round(metrics$cons, 3), "\n"))
      cat(paste("  Overall coverage:", round(metrics$cov, 3), "\n"))
    }
  } else {
    cat("No parsimonious solution found.\n")
    result$parsimonious <- NULL
  }
  
  # -------------------------------------------------------------------------
  # STEP 7: INTERMEDIATE SOLUTION
  # -------------------------------------------------------------------------
  cat("\n\nSTEP 7: INTERMEDIATE SOLUTION\n")
  cat("------------------------------\n")
  cat("(Uses remainders consistent with directional expectations)\n\n")
  
  # Get directional expectations for this outcome
  dir_exp_outcome <- dir_exp[[outcome_name]]
  
  if (!is.null(dir_exp_outcome)) {
    cat("Directional expectations (1 = presence contributes to outcome):\n")
    print(dir_exp_outcome)
    cat("\n")
    
    sol_intermediate <- tryCatch({
      minimize(tt,
               include = "?",
               dir.exp = dir_exp_outcome,
               details = TRUE,
               show.cases = TRUE)
    }, error = function(e) {
      cat(paste("Error:", e$message, "\n"))
      NULL
    })
    
    if (!is.null(sol_intermediate)) {
      tryCatch(print(sol_intermediate), error = function(e) cat("(Solution too complex to print - stored in results)\n"))
      result$intermediate <- sol_intermediate
      
      metrics <- get_solution_metrics(sol_intermediate)
      if (!is.na(metrics$cons) || !is.na(metrics$cov)) {
        cat("\nIntermediate Solution Metrics:\n")
        cat(paste("  Overall consistency:", round(metrics$cons, 3), "\n"))
        cat(paste("  Overall coverage:", round(metrics$cov, 3), "\n"))
      }
    } else {
      result$intermediate <- NULL
    }
  } else {
    cat("No directional expectations defined for this outcome.\n")
    result$intermediate <- NULL
  }
  
  # -------------------------------------------------------------------------
  # SOLUTION COMPARISON SUMMARY
  # -------------------------------------------------------------------------
  cat("\n\n=============================================================================\n")
  cat("SOLUTION COMPARISON SUMMARY\n")
  cat("=============================================================================\n\n")
  
  compare_solutions <- function(sol, name) {
    if (is.null(sol)) {
      cat(paste(name, ": No solution\n"))
      return(NULL)
    }
    
    n_paths <- length(sol$solution[[1]])
    
    # Get solution formula
    sol_formula <- paste(sol$solution[[1]], collapse = " + ")
    
    # Get metrics using helper function
    metrics <- get_solution_metrics(sol)
    cons <- if (!is.na(metrics$cons)) round(metrics$cons, 3) else NA
    cov <- if (!is.na(metrics$cov)) round(metrics$cov, 3) else NA
    
    cat(paste(name, ":\n"))
    cat(paste("  Paths:", n_paths, "\n"))
    cat(paste("  Consistency:", cons, "\n"))
    cat(paste("  Coverage:", cov, "\n"))
    cat(paste("  Formula:", sol_formula, "\n\n"))
    
    return(list(paths = n_paths, consistency = cons, coverage = cov, formula = sol_formula))
  }
  
  result$comparison <- list(
    conservative = compare_solutions(result$conservative, "CONSERVATIVE"),
    enhanced = compare_solutions(result$enhanced, "ENHANCED"),
    parsimonious = compare_solutions(result$parsimonious, "PARSIMONIOUS"),
    intermediate = compare_solutions(result$intermediate, "INTERMEDIATE")
  )
  
  # -------------------------------------------------------------------------
  # ROBUSTNESS: Check if solutions are nested
  # -------------------------------------------------------------------------
  cat("\nSOLUTION NESTING CHECK:\n")
  cat("-----------------------\n")
  cat("ESA principle: Conservative ⊇ Intermediate ⊇ Enhanced ⊇ Parsimonious\n")
  cat("(Each solution should be a subset or equal to the one above)\n\n")
  
  # This would require detailed term-by-term comparison
  # For now, just note the number of terms
  if (!is.null(result$conservative) && !is.null(result$parsimonious)) {
    n_cons <- length(result$conservative$solution[[1]])
    n_pars <- length(result$parsimonious$solution[[1]])
    
    if (n_pars <= n_cons) {
      cat("✓ Parsimonious has fewer or equal paths than conservative (expected)\n")
    } else {
      cat("⚠ Warning: Parsimonious has MORE paths than conservative (unexpected)\n")
    }
  }
  
  return(result)
}

# =============================================================================
# RUN ANALYSIS FOR ALL OUTCOMES
# =============================================================================

cat("\n")
cat("###########################################################################\n")
cat("#                                                                         #\n")
cat("#     FCDO QCA ENHANCED STANDARD ANALYSIS - FULL RESULTS                  #\n")
cat("#                                                                         #\n")
cat("###########################################################################\n")

for (outcome_name in names(outcomes)) {
  esa_results[[outcome_name]] <- run_esa_analysis(
    outcome_name = outcome_name,
    outcome_params = outcomes[[outcome_name]],
    data = data,
    conditions = conditions
  )
}

# =============================================================================
# SAVE RESULTS
# =============================================================================

cat("\n\n")
cat("=============================================================================\n")
cat("SAVING RESULTS\n")
cat("=============================================================================\n")

# Save R workspace with all results
save(esa_results, file = "fcdo_qca_esa_results.RData")
cat("Results saved to: fcdo_qca_esa_results.RData\n")

# Create summary CSV for each outcome
for (outcome_name in names(esa_results)) {
  result <- esa_results[[outcome_name]]
  
  # Extract solution summaries
  summary_df <- data.frame(
    Outcome = outcome_name,
    Solution = c("Conservative", "Enhanced", "Parsimonious", "Intermediate"),
    N_Paths = c(
      ifelse(!is.null(result$conservative), length(result$conservative$solution[[1]]), NA),
      ifelse(!is.null(result$enhanced), length(result$enhanced$solution[[1]]), NA),
      ifelse(!is.null(result$parsimonious), length(result$parsimonious$solution[[1]]), NA),
      ifelse(!is.null(result$intermediate), length(result$intermediate$solution[[1]]), NA)
    ),
    Consistency = c(
      round(get_solution_metrics(result$conservative)$cons, 3),
      round(get_solution_metrics(result$enhanced)$cons, 3),
      round(get_solution_metrics(result$parsimonious)$cons, 3),
      round(get_solution_metrics(result$intermediate)$cons, 3)
    ),
    Coverage = c(
      round(get_solution_metrics(result$conservative)$cov, 3),
      round(get_solution_metrics(result$enhanced)$cov, 3),
      round(get_solution_metrics(result$parsimonious)$cov, 3),
      round(get_solution_metrics(result$intermediate)$cov, 3)
    )
  )
  
  write.csv(summary_df, 
            file = paste0("fcdo_qca_esa_summary_", tolower(outcome_name), ".csv"),
            row.names = FALSE)
}

cat("Summary CSVs saved for each outcome.\n")

# =============================================================================
# FINAL SUMMARY
# =============================================================================

cat("\n\n")
cat("###########################################################################\n")
cat("#                         ANALYSIS COMPLETE                               #\n")
cat("###########################################################################\n\n")

cat("Results stored in 'esa_results' object with the following structure:\n\n")
cat("  esa_results$OUTCOME_NAME$\n")
cat("    $descriptives   - Outcome frequency statistics\n")
cat("    $necessity      - superSubset results for necessary conditions\n")
cat("    $truth_table    - Full truth table object\n")
cat("    $contradictions - Contradictory configurations\n")
cat("    $conservative   - Conservative (complex) solution\n")
cat("    $enhanced       - Enhanced solution (excl. contradictions)\n")
cat("    $parsimonious   - Parsimonious solution\n")
cat("    $intermediate   - Intermediate solution (with dir. expectations)\n")
cat("    $comparison     - Side-by-side comparison of all solutions\n\n")

cat("To access results interactively:\n")
cat("  load('fcdo_qca_esa_results.RData')\n")
cat("  esa_results$IMPACT_ACHIEVEMENT$parsimonious\n")
cat("  esa_results$SUSTAINABILITY$necessity\n")

# =============================================================================
# SENSITIVITY ANALYSIS: n.cut Robustness Check
# =============================================================================
# Following Schneider & Wagemann (2012, pp. 152-153), we test robustness
# of solutions across different frequency thresholds (n.cut = 1, 2, 3)
# =============================================================================

cat("\n\n")
cat("###########################################################################\n")
cat("#                    SENSITIVITY ANALYSIS: n.cut                          #\n")
cat("###########################################################################\n\n")

sensitivity_results <- list()

run_sensitivity <- function(outcome_name, data, conditions, n_cut_values = c(1, 2, 3)) {
  
  cat(paste("\n=== SENSITIVITY ANALYSIS FOR:", outcome_name, "===\n"))
  cat("Testing n.cut values:", paste(n_cut_values, collapse = ", "), "\n\n")
  
  results <- list()
  
  for (n_cut in n_cut_values) {
    cat(paste("--- n.cut =", n_cut, "---\n"))
    
    # Create truth table
    tt <- tryCatch({
      truthTable(data,
                 outcome = outcome_name,
                 conditions = conditions,
                 incl.cut = incl.cut,
                 n.cut = n_cut,
                 show.cases = TRUE)
    }, error = function(e) {
      cat(paste("  Error creating truth table:", e$message, "\n"))
      NULL
    })
    
    if (is.null(tt)) {
      results[[paste0("n", n_cut)]] <- list(
        n_cut = n_cut,
        n_sufficient = NA,
        solution = NULL,
        formula = NA,
        n_paths = NA,
        consistency = NA,
        coverage = NA
      )
      next
    }
    
    # Count sufficient configurations
    tt_df <- as.data.frame(tt$tt)
    n_sufficient <- sum(tt_df$OUT == 1, na.rm = TRUE)
    
    # Get parsimonious solution
    sol <- tryCatch({
      minimize(tt, include = "?", details = TRUE, show.cases = TRUE)
    }, error = function(e) {
      cat(paste("  Error minimizing:", e$message, "\n"))
      NULL
    })
    
    if (!is.null(sol)) {
      formula <- paste(sol$solution[[1]], collapse = " + ")
      n_paths <- length(sol$solution[[1]])
      metrics <- get_solution_metrics(sol)
      
      cat(paste("  Sufficient configs:", n_sufficient, "\n"))
      cat(paste("  N paths:", n_paths, "\n"))
      cat(paste("  Consistency:", round(metrics$cons, 3), "\n"))
      cat(paste("  Coverage:", round(metrics$cov, 3), "\n"))
      cat(paste("  Formula:", formula, "\n\n"))
      
      results[[paste0("n", n_cut)]] <- list(
        n_cut = n_cut,
        n_sufficient = n_sufficient,
        solution = sol,
        formula = formula,
        n_paths = n_paths,
        consistency = metrics$cons,
        coverage = metrics$cov
      )
    } else {
      cat("  No solution found.\n\n")
      results[[paste0("n", n_cut)]] <- list(
        n_cut = n_cut,
        n_sufficient = n_sufficient,
        solution = NULL,
        formula = NA,
        n_paths = NA,
        consistency = NA,
        coverage = NA
      )
    }
  }
  
  # Comparison summary
  cat("\n  ROBUSTNESS SUMMARY:\n")
  cat("  -------------------\n")
  
  formulas <- sapply(results, function(x) x$formula)
  unique_formulas <- unique(formulas[!is.na(formulas)])
  
  if (length(unique_formulas) == 1) {
    cat("  ✓ ROBUST: Same solution across all n.cut values\n")
  } else if (length(unique_formulas) > 1) {
    cat(paste("  ⚠ SENSITIVE:", length(unique_formulas), "different solutions found\n"))
    cat("  Consider reporting the most conservative or most common solution.\n")
  }
  
  return(results)
}

# Run sensitivity analysis for each outcome
for (outcome_name in names(outcomes)) {
  sensitivity_results[[outcome_name]] <- run_sensitivity(
    outcome_name = outcome_name,
    data = data,
    conditions = conditions,
    n_cut_values = c(1, 2, 3)
  )
}

# Save sensitivity results
save(sensitivity_results, file = "fcdo_qca_sensitivity_ncut.RData")

# Create sensitivity summary table
cat("\n\n")
cat("=============================================================================\n")
cat("SENSITIVITY SUMMARY TABLE\n")
cat("=============================================================================\n\n")

sensitivity_summary <- data.frame()

for (outcome_name in names(sensitivity_results)) {
  for (result in sensitivity_results[[outcome_name]]) {
    row <- data.frame(
      Outcome = outcome_name,
      n_cut = result$n_cut,
      N_Sufficient_Configs = result$n_sufficient,
      N_Paths = result$n_paths,
      Consistency = round(result$consistency, 3),
      Coverage = round(result$coverage, 3),
      stringsAsFactors = FALSE
    )
    sensitivity_summary <- rbind(sensitivity_summary, row)
  }
}

print(sensitivity_summary)

write.csv(sensitivity_summary, 
          file = "fcdo_qca_sensitivity_ncut_summary.csv",
          row.names = FALSE)

cat("\nSensitivity analysis saved to:\n")
cat("  - fcdo_qca_sensitivity_ncut.RData (full results)\n")
cat("  - fcdo_qca_sensitivity_ncut_summary.csv (summary table)\n")

cat("\n\n")
cat("###########################################################################\n")
cat("#                    ALL ANALYSES COMPLETE                                #\n")
cat("###########################################################################\n")
