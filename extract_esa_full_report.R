# =============================================================================
# FCDO QCA ESA Results Extraction and Analysis
# =============================================================================
# This script loads the saved ESA results and extracts key information
# from each step for proper reporting
# =============================================================================

load("fcdo_qca_esa_results.RData")

# Helper function to safely get metrics
get_metrics <- function(sol) {
  if (is.null(sol)) return(list(cons = NA, cov = NA))
  
  cons <- NA
  cov <- NA
  
  # Try direct path first
  if (!is.null(sol$IC$sol.incl.cov)) {
    cons <- sol$IC$sol.incl.cov$inclS[1]
    cov <- sol$IC$sol.incl.cov$covS[1]
  } else if (!is.null(sol$IC$overall$sol.incl.cov)) {
    cons <- sol$IC$overall$sol.incl.cov$inclS[1]
    cov <- sol$IC$overall$sol.incl.cov$covS[1]
  }
  
  return(list(cons = cons, cov = cov))
}

# =============================================================================
# EXTRACT ALL RESULTS
# =============================================================================

cat("\n")
cat("###########################################################################\n")
cat("#           FCDO QCA ENHANCED STANDARD ANALYSIS - FULL REPORT            #\n")
cat("###########################################################################\n")
cat(paste("\nReport generated:", Sys.time(), "\n"))

for (outcome_name in names(esa_results)) {
  
  result <- esa_results[[outcome_name]]
  
  cat("\n\n")
  cat("===========================================================================\n")
  cat(paste("OUTCOME:", outcome_name, "\n"))
  cat("===========================================================================\n")
  
  # -------------------------------------------------------------------------
  # STEP 0: Descriptive Statistics
  # -------------------------------------------------------------------------
  cat("\n--- STEP 0: DESCRIPTIVE STATISTICS ---\n")
  if (!is.null(result$descriptives)) {
    cat(paste("  Total cases:", result$descriptives$n_total, "\n"))
    cat(paste("  Positive cases:", result$descriptives$n_positive, "\n"))
    cat(paste("  Prevalence:", round(result$descriptives$prevalence * 100, 1), "%\n"))
  }
  
  # -------------------------------------------------------------------------
  # STEP 1: Necessity Analysis
  # -------------------------------------------------------------------------
  cat("\n--- STEP 1: NECESSITY ANALYSIS ---\n")
  if (!is.null(result$necessity)) {
    cat("  Necessary conditions found (consistency >= 0.90):\n")
    # Extract condition names and consistency values
    nec_df <- result$necessity
    print(nec_df)
  } else {
    cat("  No single conditions meet necessity threshold (0.90)\n")
  }
  
  if (!is.null(result$suin)) {
    cat("\n  SUIN conditions (necessary disjunctions):\n")
    print(result$suin)
  }
  
  # -------------------------------------------------------------------------
  # STEP 2: Truth Table Summary
  # -------------------------------------------------------------------------
  cat("\n--- STEP 2: TRUTH TABLE SUMMARY ---\n")
  if (!is.null(result$tt_summary)) {
    cat(paste("  Observed configurations:", result$tt_summary$observed, "\n"))
    cat(paste("  Sufficient configurations (OUT=1):", result$tt_summary$sufficient, "\n"))
    cat(paste("  Insufficient configurations (OUT=0):", result$tt_summary$insufficient, "\n"))
    cat(paste("  Logical remainders:", result$tt_summary$remainders, "\n"))
  }
  
  # -------------------------------------------------------------------------
  # STEP 3: Contradictory Configurations
  # -------------------------------------------------------------------------
  cat("\n--- STEP 3: CONTRADICTORY CONFIGURATIONS ---\n")
  if (!is.null(result$contradictions) && nrow(result$contradictions) > 0) {
    cat(paste("  Found", nrow(result$contradictions), "contradictory configurations\n"))
    cat(paste("  Row numbers:", paste(result$exclude_rows, collapse = ", "), "\n"))
  } else {
    cat("  No contradictory configurations found\n")
  }
  
  # -------------------------------------------------------------------------
  # STEP 4: Conservative Solution
  # -------------------------------------------------------------------------
  cat("\n--- STEP 4: CONSERVATIVE SOLUTION ---\n")
  if (!is.null(result$conservative)) {
    formulas <- result$conservative$solution[[1]]
    metrics <- get_metrics(result$conservative)
    
    cat(paste("  Number of paths:", length(formulas), "\n"))
    cat(paste("  Consistency:", round(metrics$cons, 3), "\n"))
    cat(paste("  Coverage:", round(metrics$cov, 3), "\n"))
    cat("  Pathways:\n")
    for (i in seq_along(formulas)) {
      cat(paste("    ", i, ".", formulas[i], "\n"))
    }
  } else {
    cat("  No conservative solution\n")
  }
  
  # -------------------------------------------------------------------------
  # STEP 5: Enhanced Solution
  # -------------------------------------------------------------------------
  cat("\n--- STEP 5: ENHANCED SOLUTION ---\n")
  if (!is.null(result$enhanced)) {
    formulas <- result$enhanced$solution[[1]]
    metrics <- get_metrics(result$enhanced)
    
    cat(paste("  Number of paths:", length(formulas), "\n"))
    cat(paste("  Consistency:", round(metrics$cons, 3), "\n"))
    cat(paste("  Coverage:", round(metrics$cov, 3), "\n"))
    cat("  Pathways:\n")
    for (i in seq_along(formulas)) {
      cat(paste("    ", i, ".", formulas[i], "\n"))
    }
  } else {
    cat("  No enhanced solution\n")
  }
  
  # -------------------------------------------------------------------------
  # STEP 6: Parsimonious Solution
  # -------------------------------------------------------------------------
  cat("\n--- STEP 6: PARSIMONIOUS SOLUTION ---\n")
  if (!is.null(result$parsimonious)) {
    formulas <- result$parsimonious$solution[[1]]
    metrics <- get_metrics(result$parsimonious)
    
    cat(paste("  Number of paths:", length(formulas), "\n"))
    cat(paste("  Consistency:", round(metrics$cons, 3), "\n"))
    cat(paste("  Coverage:", round(metrics$cov, 3), "\n"))
    cat("  Pathways:\n")
    for (i in seq_along(formulas)) {
      cat(paste("    ", i, ".", formulas[i], "\n"))
    }
    
    # Individual pathway metrics if available
    if (!is.null(result$parsimonious$IC$incl.cov)) {
      cat("\n  Individual pathway metrics:\n")
      ic <- result$parsimonious$IC$incl.cov
      for (i in 1:nrow(ic)) {
        cat(paste("    Path", i, ": inclS =", round(ic$inclS[i], 3), 
                  ", covS =", round(ic$covS[i], 3), 
                  ", covU =", round(ic$covU[i], 3), "\n"))
      }
    }
  } else {
    cat("  No parsimonious solution\n")
  }
  
  # -------------------------------------------------------------------------
  # STEP 7: Intermediate Solution
  # -------------------------------------------------------------------------
  cat("\n--- STEP 7: INTERMEDIATE SOLUTION ---\n")
  if (!is.null(result$intermediate)) {
    formulas <- result$intermediate$solution[[1]]
    metrics <- get_metrics(result$intermediate)
    
    cat(paste("  Number of paths:", length(formulas), "\n"))
    cat(paste("  Consistency:", round(metrics$cons, 3), "\n"))
    cat(paste("  Coverage:", round(metrics$cov, 3), "\n"))
    cat("  Pathways:\n")
    for (i in seq_along(formulas)) {
      cat(paste("    ", i, ".", formulas[i], "\n"))
    }
  } else {
    cat("  No intermediate solution\n")
  }
  
  # -------------------------------------------------------------------------
  # Solution Comparison
  # -------------------------------------------------------------------------
  cat("\n--- SOLUTION COMPARISON ---\n")
  
  # Check if solutions are the same
  pars_formula <- if(!is.null(result$parsimonious)) paste(result$parsimonious$solution[[1]], collapse = " + ") else NA
  enh_formula <- if(!is.null(result$enhanced)) paste(result$enhanced$solution[[1]], collapse = " + ") else NA
  int_formula <- if(!is.null(result$intermediate)) paste(result$intermediate$solution[[1]], collapse = " + ") else NA
  
  if (!is.na(pars_formula) && !is.na(enh_formula) && pars_formula == enh_formula) {
    cat("  ✓ Enhanced = Parsimonious (no contradictory remainders affected result)\n")
  }
  if (!is.na(pars_formula) && !is.na(int_formula) && pars_formula == int_formula) {
    cat("  ✓ Intermediate = Parsimonious (directional expectations didn't constrain)\n")
  }
}

# =============================================================================
# SUMMARY TABLE
# =============================================================================

cat("\n\n")
cat("###########################################################################\n")
cat("#                         SUMMARY TABLE                                   #\n")
cat("###########################################################################\n\n")

summary_table <- data.frame(
  Outcome = character(),
  Prevalence = character(),
  N_Paths = integer(),
  Consistency = numeric(),
  Coverage = numeric(),
  Meets_Threshold = character(),
  stringsAsFactors = FALSE
)

for (outcome_name in names(esa_results)) {
  result <- esa_results[[outcome_name]]
  
  prev <- if(!is.null(result$descriptives)) paste0(round(result$descriptives$prevalence * 100, 1), "%") else NA
  
  if (!is.null(result$parsimonious)) {
    n_paths <- length(result$parsimonious$solution[[1]])
    metrics <- get_metrics(result$parsimonious)
    meets <- if(!is.na(metrics$cons) && metrics$cons >= 0.85) "Yes" else "No"
  } else {
    n_paths <- NA
    metrics <- list(cons = NA, cov = NA)
    meets <- "No solution"
  }
  
  summary_table <- rbind(summary_table, data.frame(
    Outcome = outcome_name,
    Prevalence = prev,
    N_Paths = n_paths,
    Consistency = round(metrics$cons, 3),
    Coverage = round(metrics$cov, 3),
    Meets_Threshold = meets,
    stringsAsFactors = FALSE
  ))
}

print(summary_table)

# Save summary table
write.csv(summary_table, "fcdo_qca_esa_final_summary.csv", row.names = FALSE)
cat("\nSummary saved to: fcdo_qca_esa_final_summary.csv\n")

cat("\n###########################################################################\n")
cat("#                         END OF REPORT                                   #\n")
cat("###########################################################################\n")
