# Quick verification script for contradiction counts
# This script loads the QCA results and checks for contradictions in each outcome

library(QCA)

# Load the saved results
load("fcdo_qca_esa_results.RData")

cat("=============================================================\n")
cat("VERIFICATION OF CONTRADICTIONS IN TRUTH TABLES\n")
cat("=============================================================\n\n")

# Check each outcome
for (outcome in names(esa_results)) {
  cat(paste0(">>> ", outcome, " <<<\n"))
  cat("--------------------------\n")
  
  result <- esa_results[[outcome]]
  
  # 1. Check if contradictions were stored
  if (!is.null(result$contradictions)) {
    cat("Contradictions object exists:\n")
    if (is.data.frame(result$contradictions)) {
      cat(paste("  Number of contradictory rows:", nrow(result$contradictions), "\n"))
    } else {
      cat("  Content: ", result$contradictions, "\n")
    }
  } else {
    cat("Contradictions object: NULL (no contradictions found)\n")
  }
  
  # 2. Check exclude_rows
  if (!is.null(result$exclude_rows)) {
    cat(paste("Rows to exclude:", paste(result$exclude_rows, collapse = ", "), "\n"))
  } else {
    cat("Rows to exclude: None\n")
  }
  
  # 3. Verify from truth table directly
  tt <- result$truth_table
  if (!is.null(tt) && !is.null(tt$tt)) {
    tt_df <- as.data.frame(tt$tt)
    n_cut <- result$parameters$n.cut
    incl_cut <- 0.85  # From the original analysis
    
    # Find rows with enough cases but consistency between 0 and incl.cut
    rows_with_cases <- tt_df[tt_df$n >= n_cut, ]
    potentially_contradictory <- rows_with_cases[
      rows_with_cases$incl > 0 & rows_with_cases$incl < incl_cut, ]
    
    cat(paste("\nDirect verification from truth table:\n"))
    cat(paste("  n.cut threshold:", n_cut, "\n"))
    cat(paste("  Rows with n >= n.cut:", nrow(rows_with_cases), "\n"))
    cat(paste("  Rows with 0 < incl < 0.85 (contradictory):", nrow(potentially_contradictory), "\n"))
    
    if (nrow(potentially_contradictory) > 0) {
      cat("\n  Contradictory rows details:\n")
      print(potentially_contradictory[, c("n", "incl", "PRI", "OUT")])
    }
  }
  
  cat("\n\n")
}

cat("=============================================================\n")
cat("VERIFICATION COMPLETE\n")
cat("=============================================================\n")
