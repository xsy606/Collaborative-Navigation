# USV-AUV Cooperative Navigation Static Project

This ASCII/English README is provided to avoid Windows console encoding
issues when the Chinese README is displayed in legacy code pages.

## Purpose

This project studies USV-assisted AUV localization using static or
quasi-static USV formations. It evaluates line, wedge, and polygon
formations using acoustic-ranging constraints, dynamic BCRLB recursion,
engineering cost proxies, robust strategy search, and Monte Carlo EKF
verification.

## Quick Start

```matlab
cfg = init_workspace();
main_run_all
```

For denser paper-style grids:

```matlab
cfg = init_workspace('paper');
out = main_paper_run_all();
```

## Reproducibility

Use:

```matlab
main_run_smoke_tests
```

The `util/save_experiment_artifacts.m` helper saves:

- `config_snapshot.mat`
- `<name>_result.mat`
- `run_info.txt`
- `figures/*.png` and `figures/*.fig`
- `tables/*.csv`

## Key Entry Points

- `main_fig1_ellipse_paper.m` to `main_fig6_spatial_precision_map.m`
- `main_scheme1_offline.m`
- `main_paper_baseline_ablation.m`
- `main_paper_noise_sensitivity.m`
- `main_paper_pareto_analysis.m`
- `main_scheme2_robust.m`
- `main_scheme3_mc_verify.m`
- `main_paper_run_all.m`

## Paper Figure Styling

Paper-oriented scripts use the shared helpers in `viz/`:

- `paper_style.m`, `new_paper_figure.m`, and `apply_axis_style.m` set the
  typography, grid, axis, and figure defaults.
- `family_style.m` and `paper_palette.m` keep line/wedge/polygon colors,
  markers, and supporting colors consistent across figures.
- `plot_target_band.m`, `annotate_best_point.m`, and `fill_between_curve.m`
  add target-accuracy bands, key-point callouts, and uncertainty bands.

## Recent Improvements

- Reworked `main_scheme1_offline.m` to use compact one-pass design tables
  in paper mode, avoiding the previous full-record persistent cache that
  could exhaust MATLAB memory.
- `main_paper_run_all.m` now saves figures immediately after each section,
  so earlier figures are not lost when later scripts call `close all`.
- Added `RESULT_FIGURE_GUIDE_CN.md` with the meaning and expected trend of
  each major result figure.
- Upgraded paper plots with a unified visual system, target bands,
  recommended-design callouts, uncertainty shading, and improved spatial
  precision maps.
- Added Pareto-front analysis for RMSE, cost, footprint, and update rate.
- Baseline plots now separate weak sanity baselines from fair cooperative
  baselines to avoid misleading scale compression.
- Sensitivity plots now include normalized single-axis summaries.
- Pareto analysis now reports target-feasible Pareto designs separately.
- Added bootstrap 95% confidence intervals for final Monte Carlo errors in
  `run_mc_ekf.m`.
- Added smoke tests and reproducible experiment artifact export.
