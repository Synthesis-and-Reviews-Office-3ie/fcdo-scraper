# Quick script to check ESA results
# Run this after fcdo_qca_esa_analysis.R completes

# Load results if not already in memory
if (!exists("esa_results")) {
  load("fcdo_qca_esa_results.RData")
}

cat("\n")
cat("=============================================================================\n")
cat("ESA RESULTS SUMMARY\n")
cat("=============================================================================\n\n")

for (outcome in names(esa_results)) {
  cat(paste("\n###", outcome, "###\n"))
  cat("-----------------------------------------\n")
  
  result <- esa_results[[outcome]]
  
  # Descriptives
  if (!is.null(result$descriptives)) {
    cat(paste("Prevalence:", round(result$descriptives$prevalence * 100, 1), "%\n"))
    cat(paste("N positive:", result$descriptives$n_positive, "/", result$descriptives$n_total, "\n"))
  }
  
  # Necessity
  if (!is.null(result$necessity)) {
    cat("\nNECESSARY CONDITIONS (cons >= 0.90):\n")
    print(result$necessity)
  } else {
    cat("\nNo necessary conditions found.\n")
  }
  
  # Truth table summary
  if (!is.null(result$tt_summary)) {
    cat(paste("\nTruth Table: ", result$tt_summary$observed, " observed configs, ",
              result$tt_summary$sufficient, " sufficient\n", sep = ""))
  }
  
  # Solutions
  cat("\nSOLUTIONS:\n")
  
  # Conservative
  if (!is.null(result$conservative)) {
    cat("\n  CONSERVATIVE:\n")
    cat(paste("    Formula:", paste(result$conservative$solution[[1]], collapse = " + "), "\n"))
  } else {
    cat("\n  CONSERVATIVE: None\n")
  }
  
  # Parsimonious
  if (!is.null(result$parsimonious)) {
    cat("\n  PARSIMONIOUS:\n")
    cat(paste("    Formula:", paste(result$parsimonious$solution[[1]], collapse = " + "), "\n"))
  } else {
    cat("\n  PARSIMONIOUS: None\n")
  }
  
  # Intermediate
  if (!is.null(result$intermediate)) {
    cat("\n  INTERMEDIATE:\n")
    cat(paste("    Formula:", paste(result$intermediate$solution[[1]], collapse = " + "), "\n"))
  } else {
    cat("\n  INTERMEDIATE: None\n")
  }
  
  cat("\n")
}

cat("\n=============================================================================\n")
cat("END OF SUMMARY\n")
cat("=============================================================================\n")
