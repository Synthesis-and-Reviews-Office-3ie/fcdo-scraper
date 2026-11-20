# Run necessity analysis for IMPACT_ACHIEVEMENT and SUSTAINABILITY
library(QCA)

# Load data
data <- read.csv("fcdo_qca_rich_binary.csv")

conditions <- c("StrategicAgendaClarity", "SharedGovernance", "FundingFlexibility", 
                "SelectionProcedures", "OutputsAccessible", "OutputsCapacity", 
                "LocalEmbedded", "ImpactStrategy", "PartnershipEquity", 
                "EquityLocalisation", "EquityGESI", "FundingLongevity_ADAPTED", 
                "InstabilityResponse", "MEL_STRENGTHENED")

cat("=============================================================\n")
cat("NECESSITY ANALYSIS FOR HIGH-PREVALENCE OUTCOMES\n")
cat("=============================================================\n\n")

# Function to calculate necessity for single conditions
calc_necessity <- function(data, outcome_name, conditions) {
  outcome <- data[[outcome_name]]
  n_positive <- sum(outcome == 1, na.rm = TRUE)
  n_total <- sum(!is.na(outcome))
  prevalence <- n_positive / n_total
  
  cat("\n###", outcome_name, "###\n")
  cat("Prevalence:", n_positive, "/", n_total, "(", round(prevalence*100, 1), "%)\n")
  cat("WARNING: High prevalence inflates necessity scores through base-rate artifacts\n\n")
  
  results <- data.frame(
    Condition = character(),
    inclN = numeric(),
    covN = numeric(),
    stringsAsFactors = FALSE
  )
  
  for (cond in conditions) {
    cond_vec <- data[[cond]]
    
    # Necessity: inclN = sum(outcome & condition) / sum(outcome)
    # covN = sum(outcome & condition) / sum(condition)
    both <- sum(outcome == 1 & cond_vec == 1, na.rm = TRUE)
    inclN <- both / n_positive
    covN <- both / sum(cond_vec == 1, na.rm = TRUE)
    
    results <- rbind(results, data.frame(
      Condition = cond,
      inclN = inclN,
      covN = covN,
      stringsAsFactors = FALSE
    ))
  }
  
  # Sort by inclN descending
  results <- results[order(-results$inclN), ]
  rownames(results) <- NULL
  
  cat("All single conditions (sorted by necessity consistency):\n")
  print(results, digits = 4)
  
  # Filter >= 0.90
  nec_pass <- results[results$inclN >= 0.90, ]
  cat("\nConditions meeting 0.90 threshold:\n")
  if(nrow(nec_pass) > 0) {
    print(nec_pass, digits = 4)
  } else {
    cat("  None\n")
  }
  
  return(results)
}

# Run for IMPACT_ACHIEVEMENT
impact_nec <- calc_necessity(data, "IMPACT_ACHIEVEMENT", conditions)

cat("\n\n")

# Run for SUSTAINABILITY  
sust_nec <- calc_necessity(data, "SUSTAINABILITY", conditions)

# Save results
write.csv(impact_nec, "fcdo_qca_impact_necessity_full.csv", row.names = FALSE)
write.csv(sust_nec, "fcdo_qca_sustainability_necessity_full.csv", row.names = FALSE)

cat("\n\nResults saved to CSV files.\n")
