load("fcdo_qca_esa_results.RData")

for(o in names(esa_results)) {
  prev <- esa_results[[o]]$descriptives$prevalence
  has_nec <- !is.null(esa_results[[o]]$necessity)
  cat(o, ": has_necessity=", has_nec, ", prevalence=", round(prev*100,1), "%\n")
}
