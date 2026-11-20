# Diagnostic: Check EQUITY_OUTCOMES solution structure
load("fcdo_qca_esa_results.RData")

cat("=== EQUITY_OUTCOMES Parsimonious Solution ===\n\n")

sol <- esa_results$EQUITY_OUTCOMES$parsimonious

if (is.null(sol)) {
  cat("Solution is NULL\n")
} else {
  cat("Solution exists\n")
  cat("\nFormula:\n")
  print(sol$solution[[1]])
  
  cat("\n\n=== Checking IC structure ===\n")
  cat("names(sol$IC):", paste(names(sol$IC), collapse = ", "), "\n")
  
  cat("\n--- sol$IC$overall ---\n")
  if (!is.null(sol$IC$overall)) {
    cat("names(sol$IC$overall):", paste(names(sol$IC$overall), collapse = ", "), "\n")
    
    if (!is.null(sol$IC$overall$sol.incl.cov)) {
      cat("\nsol$IC$overall$sol.incl.cov:\n")
      print(sol$IC$overall$sol.incl.cov)
    } else {
      cat("sol$IC$overall$sol.incl.cov is NULL\n")
    }
  } else {
    cat("sol$IC$overall is NULL\n")
  }
  
  cat("\n--- sol$IC$individual ---\n")
  if (!is.null(sol$IC$individual) && length(sol$IC$individual) > 0) {
    cat("Number of individual solutions:", length(sol$IC$individual), "\n")
    cat("\nFirst individual solution:\n")
    ind <- sol$IC$individual[[1]]
    cat("names:", paste(names(ind), collapse = ", "), "\n")
    if (!is.null(ind$sol.incl.cov)) {
      cat("\nsol.incl.cov:\n")
      print(ind$sol.incl.cov)
    }
  } else {
    cat("No individual solutions\n")
  }
}
