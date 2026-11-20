# Extract ESA formulas from results
load("fcdo_qca_esa_results.RData")

cat("\n")
cat("###########################################################################\n")
cat("#                    ESA RESULTS - PATHWAY FORMULAS                       #\n")
cat("###########################################################################\n")

for (outcome in names(esa_results)) {
  cat(paste("\n\n===", outcome, "===\n"))
  cat("=====================================\n")
  
  result <- esa_results[[outcome]]
  
  # Descriptives
  if (!is.null(result$descriptives)) {
    cat(paste("Prevalence:", round(result$descriptives$prevalence * 100, 1), "%\n"))
  }
  
  # Conservative
  cat("\nCONSERVATIVE SOLUTION:\n")
  if (!is.null(result$conservative)) {
    formula <- paste(result$conservative$solution[[1]], collapse = "\n  + ")
    cat(paste("  ", formula, "\n"))
  } else {
    cat("  None\n")
  }
  
  # Parsimonious (most simplified)
  cat("\nPARSIMONIOUS SOLUTION:\n")
  if (!is.null(result$parsimonious)) {
    formula <- paste(result$parsimonious$solution[[1]], collapse = "\n  + ")
    cat(paste("  ", formula, "\n"))
    
    # Get metrics
    if (!is.null(result$parsimonious$IC$overall$sol.incl.cov)) {
      metrics <- result$parsimonious$IC$overall$sol.incl.cov
      cat(paste("  Consistency:", round(metrics$inclS, 3), "\n"))
      cat(paste("  Coverage:", round(metrics$covS, 3), "\n"))
    }
  } else {
    cat("  None\n")
  }
  
  # Intermediate
  cat("\nINTERMEDIATE SOLUTION:\n")
  if (!is.null(result$intermediate)) {
    formula <- paste(result$intermediate$solution[[1]], collapse = "\n  + ")
    cat(paste("  ", formula, "\n"))
  } else {
    cat("  None\n")
  }
}

cat("\n\n###########################################################################\n")
cat("#                           END OF RESULTS                                #\n")
cat("###########################################################################\n")
