library(QCA)
data <- read.csv('fcdo_qca_rich_binary.csv')

# Define conditions
conditions <- c('StrategicAgendaClarity', 'SharedGovernance', 'FundingFlexibility', 
                'SelectionProcedures', 'OutputsAccessible', 'OutputsCapacity', 
                'LocalEmbedded', 'ImpactStrategy', 'FundingLongevity_ADAPTED', 
                'MEL_STRENGTHENED', 'InstabilityResponse', 'PartnershipEquity', 
                'EquityLocalisation', 'EquityGESI')

# HIGH_PERFORMANCE necessity
hp_nec <- pof(data[, conditions], data[['HIGH_PERFORMANCE']], relation = 'nec')
hp_df <- data.frame(Condition = rownames(hp_nec$incl.cov), 
                    inclN = hp_nec$incl.cov[,1], 
                    covN = hp_nec$incl.cov[,2])
hp_df <- hp_df[order(-hp_df$inclN),]
write.csv(hp_df, 'fcdo_qca_high_performance_necessity_full.csv', row.names = FALSE)
cat('HIGH_PERFORMANCE saved\n')

# EQUITY_OUTCOMES necessity
eq_nec <- pof(data[, conditions], data[['EQUITY_OUTCOMES']], relation = 'nec')
eq_df <- data.frame(Condition = rownames(eq_nec$incl.cov), 
                    inclN = eq_nec$incl.cov[,1], 
                    covN = eq_nec$incl.cov[,2])
eq_df <- eq_df[order(-eq_df$inclN),]
write.csv(eq_df, 'fcdo_qca_equity_outcomes_necessity_full.csv', row.names = FALSE)
cat('EQUITY_OUTCOMES saved\n')

cat('\nHIGH_PERFORMANCE top 5:\n')
print(head(hp_df, 5))
cat('\nEQUITY_OUTCOMES top 5:\n')
print(head(eq_df, 5))
