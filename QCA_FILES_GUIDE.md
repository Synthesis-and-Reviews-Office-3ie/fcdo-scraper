# FCDO QCA Analysis - Files Guide

**Last Updated:** December 5, 2025

This document explains which files are actively used for the QCA analysis and presentation.

---

## 🎯 PRIMARY FILES (Currently Active)

### Root Directory
| File | Description |
|------|-------------|
| `compare_cons_pars.R` | **Main QCA analysis script** — runs parsimonious solutions for all 4 outcomes using 14 conditions |
| `fcdo_qca_rich_binary.csv` | **Main dataset** — 312 programmes with 14 binary conditions + 4 outcomes |
| `fcdo_qca_presentation_v3.qmd` | **Current presentation** — verified parsimonious results |
| `fcdo_qca_presentation_v3.html` | Rendered HTML output |
| `fcdo_analysis_paper3.qmd` | **Academic paper** — detailed QCA methodology and findings |
| `fcdo_qca_rich_workspace.RData` | R workspace with loaded data |
| `custom.scss` | Presentation styling |
| `main.py` | Main Python scraper |
| `scrape_business_cases.py` | Business case scraping script |

### Data Directory (`data/`)
| File | Description |
|------|-------------|
| `fcdo_qca_rich_dataset.csv` | Full dataset with fuzzy scores (before binarization) |
| `fcdo_qca_dataset.csv` | Original QCA dataset |
| `extraction_definitive.json` | Business case extractions |
| `fcdo_annual_reviews_comprehensive.json` | Annual review extractions |
| `fcdo_annual_reviews_comprehensive_summary.csv` | Annual review summary |
| `fcdo_qca_rich_ar.json` | Rich annual review data |
| `fcdo_qca_rich_bc.json` | Rich business case data |

### Other Directories
| Directory | Description |
|-----------|-------------|
| `documents/` | Downloaded PDFs organized by programme ID |
| `archive/` | Old scripts, outputs, and documentation |

---

## 📊 VERIFIED QCA RESULTS (Parsimonious Solution)

**Source:** Results from running `compare_cons_pars.R` on December 5, 2025.

**Methodology:**
- **Solution type:** Parsimonious (`include = "?"` in `minimize()`)
- **Inclusion cut:** 0.85 for all outcomes
- **Frequency cut (n.cut):** 2 for rare outcomes (HIGH_PERFORMANCE, EQUITY), 3 for common outcomes (IMPACT, SUSTAINABILITY)
- **Conditions:** 14 binary conditions (see below)

### HIGH_PERFORMANCE (15.7% prevalence, N=49)
| Parameter | Value |
|-----------|-------|
| n.cut | 2 |
| incl.cut | 0.85 |
| **Status** | ❌ **FAILS** consistency threshold |
| Consistency | 0.286 (far below 0.85 required) |
| Coverage | 8.2% |
| Pathways | 2 (unreliable) |

**Interpretation:** No reliable pathways exist. Exceptional A++/A+ performance involves unmeasured factors (leadership, political economy, luck).

### IMPACT_ACHIEVEMENT (79.5% prevalence, N=248)
| Parameter | Value |
|-----------|-------|
| n.cut | 3 |
| incl.cut | 0.85 |
| **Status** | ✅ **VALID** |
| Consistency | 0.881 |
| Coverage | 74.6% |
| Pathways | 4 |

**Pathways:**
1. `OutputsAccessible` — *Accessible outputs alone is sufficient*
2. `PartnershipEquity * ~EquityGESI`
3. `~SharedGovernance * OutputsCapacity * ~FundingLongevity_ADAPTED`
4. `~SharedGovernance * ~LocalEmbedded * ImpactStrategy`

**Key message:** "Accessibility is the gateway to impact" — OutputsAccessible alone is sufficient.

### SUSTAINABILITY (69.2% prevalence, N=216)
| Parameter | Value |
|-----------|-------|
| n.cut | 3 |
| incl.cut | 0.85 |
| **Status** | ✅ **VALID** |
| Consistency | 0.870 |
| Coverage | 64.8% |
| Pathways | 3 |

**Pathways:**
1. `OutputsAccessible * OutputsCapacity` — *Outputs strategy*
2. `SharedGovernance * LocalEmbedded * FundingLongevity_ADAPTED` — *Ownership strategy*
3. `~SelectionProcedures * ~OutputsCapacity * FundingLongevity_ADAPTED`

**Key message:** "Pick your sustainability strategy" — Two genuinely different paths exist.

### EQUITY_OUTCOMES (33.7% prevalence, N=105)
| Parameter | Value |
|-----------|-------|
| n.cut | 2 |
| incl.cut | 0.85 |
| **Status** | ✅ **VALID** |
| Consistency | 0.987 (highest) |
| Coverage | 74.3% |
| Pathways | 3 |

**Pathways:**
1. `SelectionProcedures * EquityGESI`
2. `~LocalEmbedded * EquityGESI`
3. `OutputsAccessible * EquityGESI * InstabilityResponse`

**Key message:** "GESI is non-negotiable for equity" — EquityGESI appears in ALL 3 pathways (100%).

---

## 📁 THE 14 CONDITIONS

All conditions are binary (1 = present, 0 = absent), calibrated using ≥0.67 threshold on fuzzy scores.

### From Business Cases (Baseline Design)
| # | Condition | Description |
|---|-----------|-------------|
| 1 | `StrategicAgendaClarity` | Clear strategic objectives and theory of change at design |
| 2 | `SharedGovernance` | Inclusive governance with partner stakeholders in decisions |
| 3 | `FundingFlexibility` | Flexible funding allowing adaptive reallocation |
| 4 | `SelectionProcedures` | Competitive/transparent partner selection processes |

### From Annual Reviews (Implementation Reality)
| # | Condition | Description |
|---|-----------|-------------|
| 5 | `OutputsAccessible` | Outputs reached intended beneficiaries in usable formats |
| 6 | `OutputsCapacity` | Outputs built sustainable local capacity |
| 7 | `LocalEmbedded` | Activities embedded in local systems and institutions |
| 8 | `ImpactStrategy` | Clear impact strategy maintained during implementation |
| 9 | `PartnershipEquity` | Equitable partnerships with balanced power |
| 10 | `EquityLocalisation` | Resources/decisions localized to marginalized communities |
| 11 | `EquityGESI` | Gender Equality & Social Inclusion operationalized |

### Adaptation Variables (Changes During Implementation)
| # | Condition | Description |
|---|-----------|-------------|
| 12 | `FundingLongevity_ADAPTED` | Duration extended beyond original plan |
| 13 | `InstabilityResponse` | Programme adapted to instability/crises |
| 14 | `MEL_STRENGTHENED` | M&E systems strengthened during implementation |

---

## 📂 ARCHIVED FILES

Old scripts, outputs, and documentation have been moved to `archive/`:

| Subfolder | Contents |
|-----------|----------|
| `archive/old_r_scripts/` | Previous R analysis scripts (including `fcdo_qca_parsimonious.R` which used different conditions) |
| `archive/old_python_scripts/` | Debug/test Python scripts |
| `archive/old_presentations/` | Previous presentation versions (v1, v2) |
| `archive/old_papers/` | Previous paper versions |
| `archive/old_outputs/` | Old datasets and QCA outputs |
| `archive/old_documentation/` | Old guides and planning docs |

---

## ⚠️ IMPORTANT NOTES

1. **Always use PARSIMONIOUS solution** (`include = "?"` in `minimize()`)
2. **HIGH_PERFORMANCE fails** the 0.85 consistency threshold — do not present as valid pathways
3. **Coverage values are SOLUTION coverage**, not individual pathway coverage
4. **The main R script is `compare_cons_pars.R`** — NOT `fcdo_qca_parsimonious.R` (which uses different conditions)
5. **Data file:** `fcdo_qca_rich_binary.csv` is in ROOT directory, not in `data/`
6. **GESI = Gender Equality and Social Inclusion** — appears in 100% of equity pathways

---

## 🔄 How to Reproduce Results

```r
# In R, from the project root directory:
source("compare_cons_pars.R")

# This will output all parsimonious solutions with:
# - Pathway formulas
# - Consistency values  
# - Coverage values

# The script reads: fcdo_qca_rich_binary.csv (in root)
# Parameters: incl.cut=0.85, n.cut=2 (rare) or 3 (common), include="?"
```

---

## 📝 Presentation Version History

| Version | Date | Notes |
|---------|------|-------|
| v1 | Nov 2025 | Initial 8-condition model |
| v2 | Dec 2025 | 14-condition model (unverified values) |
| v3 | Dec 5, 2025 | **Current** - Verified parsimonious results |
