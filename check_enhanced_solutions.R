# Check Enhanced vs Parsimonious solutions for each outcome
library(QCA)

load("fcdo_qca_esa_results.RData")

cat("=============================================================\n")
cat("COMPARING ENHANCED VS PARSIMONIOUS SOLUTIONS\n")
cat("=============================================================\n\n")

for (outcome in names(esa_results)) {
  cat(paste0(">>> ", outcome, " <<<\n"))
  cat("--------------------------\n")
  
  result <- esa_results[[outcome]]
  
  # Check Enhanced solution
  if (!is.null(result$enhanced)) {
    cat("ENHANCED Solution:\n")
    enh <- result$enhanced
    if (!is.null(enh$IC$sol.incl.cov)) {
      cat(paste("  Consistency:", round(enh$IC$sol.incl.cov$inclS[1], 3), "\n"))
      cat(paste("  Coverage:", round(enh$IC$sol.incl.cov$covS[1], 3), "\n"))
    }
    # Print pathways
    if (!is.null(enh$solution)) {
      cat(paste("  Number of pathways:", length(enh$solution[[1]]), "\n"))
      cat("  Pathways:\n")
      for (i in seq_along(enh$solution[[1]])) {
        cat(paste("    ", i, ":", enh$solution[[1]][i], "\n"))
      }
    }
  } else {
    cat("ENHANCED: NULL\n")
  }
  
  cat("\n")
  
  # Check Parsimonious solution
  if (!is.null(result$parsimonious)) {
    cat("PARSIMONIOUS Solution:\n")
    pars <- result$parsimonious
    if (!is.null(pars$IC$sol.incl.cov)) {
      cat(paste("  Consistency:", round(pars$IC$sol.incl.cov$inclS[1], 3), "\n"))
      cat(paste("  Coverage:", round(pars$IC$sol.incl.cov$covS[1], 3), "\n"))
    }
    # Print pathways
    if (!is.null(pars$solution)) {
      cat(paste("  Number of pathways:", length(pars$solution[[1]]), "\n"))
      cat("  Pathways:\n")
      for (i in seq_along(pars$solution[[1]])) {
        cat(paste("    ", i, ":", pars$solution[[1]][i], "\n"))
      }
    }
  } else {
    cat("PARSIMONIOUS: NULL\n")
  }
  
  cat("\n\n")
}
