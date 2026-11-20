# Debug script to check QCA solution structure
library(QCA)

# Load data
data <- read.csv("fcdo_qca_rich_binary.csv")

conditions <- c("StrategicAgendaClarity", "SharedGovernance", "FundingFlexibility",
                "SelectionProcedures", "OutputsAccessible", "OutputsCapacity",
                "LocalEmbedded", "ImpactStrategy", "PartnershipEquity",
                "EquityLocalisation", "EquityGESI", "FundingLongevity_ADAPTED",
                "InstabilityResponse", "MEL_STRENGTHENED")

# Create truth table for SUSTAINABILITY
tt <- truthTable(data,
                 outcome = "SUSTAINABILITY",
                 conditions = conditions,
                 incl.cut = 0.85,
                 n.cut = 3,
                 show.cases = TRUE)

# Get parsimonious solution
sol <- minimize(tt, include = "?", details = TRUE, show.cases = TRUE)

# Deep inspection of IC
cat("\n=== DEEP INSPECTION OF sol$IC ===\n")
cat("Class:", class(sol$IC), "\n")
cat("typeof:", typeof(sol$IC), "\n")
cat("Mode:", mode(sol$IC), "\n")

cat("\n=== str(sol$IC) ===\n")
str(sol$IC)

cat("\n=== unclass(sol$IC) ===\n")
print(unclass(sol$IC))

cat("\n=== names(unclass(sol$IC)) ===\n")
print(names(unclass(sol$IC)))
