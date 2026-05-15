# Codex Change Log

## 2026-05-15

### Stability and performance

- Reworked `main_scheme1_offline.m` to use compact one-pass design tables per
  family/GNSS value instead of a persistent cache of full BCRLB records.
- Added lightweight BCRLB evaluation through `evaluate_design(...,
  'StoreSeries', false)` and `cfg.num.store_pseries`.
- Updated grid-search and sweep scripts to avoid storing unused full
  covariance time series.
- Preserved the default full-series behavior for Monte Carlo/EKF validation,
  where `Pseries` is required.

### Paper outputs

- Fixed `main_paper_run_all.m` so figures are saved immediately after each
  section. Earlier figures are no longer lost when later scripts call
  `close all`.
- Added Scheme 1 to the paper run-all pipeline and export tables.

### Documentation

- Added `RESULT_FIGURE_GUIDE_CN.md`, explaining the purpose and expected
  trends of each major result figure.
- Updated `README_EN.md` with the Scheme 1 stability fix and paper-output
  changes.

### Verification

- `checkcode` passed for 19 modified MATLAB files.
- `main_run_smoke_tests` passed.
- `main_scheme1_offline('tune')` passed.
- `main_scheme1_offline('paper')` passed in about 146 seconds.
- Representative paper entries passed in tune mode:
  `main_paper_baseline_ablation('tune')`,
  `main_paper_pareto_analysis('tune')`, and
  `main_scheme3_mc_verify_paper('tune')`.
