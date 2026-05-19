function OUT = main_paper_run_all()
%MAIN_PAPER_RUN_ALL Run paper-oriented experiments and save outputs.

close all;
paper_style();
cfg = init_workspace('paper');

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
outRoot = fullfile(pwd, 'paper_outputs', stamp);
figDir = fullfile(outRoot, 'figures');
tableDir = fullfile(outRoot, 'tables');

if ~exist(figDir, 'dir'), mkdir(figDir); end
if ~exist(tableDir, 'dir'), mkdir(tableDir); end

OUT = struct();
OUT.cfg = cfg;
OUT.outputRoot = outRoot;
OUT.savedFigures = strings(0,2);

fprintf('\n========== Paper Figure 1 ==========\n');
OUT.fig1 = main_fig1_ellipse_paper();
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'fig1_')];

fprintf('\n========== Paper Figure 2 ==========\n');
OUT.fig2 = main_fig2_spacing_paper();
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'fig2_')];

fprintf('\n========== Paper Figure 3 ==========\n');
OUT.fig3 = main_fig3_wedge_angle_paper();
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'fig3_')];

fprintf('\n========== Paper Figure 4 ==========\n');
OUT.fig4 = main_fig4_rate_paper();
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'fig4_')];

fprintf('\n========== Paper Figure 5 ==========\n');
OUT.fig5 = main_fig5_gnss_degradation_paper();
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'fig5_')];

fprintf('\n========== Paper Figure 6 ==========\n');
OUT.fig6 = main_fig6_spatial_precision_map();
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'fig6_')];

fprintf('\n========== Paper Geometry Fairness ==========\n');
OUT.geometryFairness = main_paper_geometry_fairness('paper');
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'geometry_fairness_')];

fprintf('\n========== Paper Scheme 1 ==========\n');
OUT.scheme1 = main_scheme1_offline('paper');
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'scheme1_')];

fprintf('\n========== Paper Baseline Ablation ==========\n');
OUT.baseline = main_paper_baseline_ablation('paper');
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'baseline_')];

fprintf('\n========== Paper Noise Sensitivity ==========\n');
OUT.noise = main_paper_noise_sensitivity('paper');
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'noise_')];

fprintf('\n========== Paper Pareto Analysis ==========\n');
OUT.pareto = main_paper_pareto_analysis('paper');
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'pareto_')];

fprintf('\n========== Paper Scheme 2 ==========\n');
OUT.scheme2 = main_scheme2_robust_paper();
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'scheme2_')];

fprintf('\n========== Paper Scheme 3 ==========\n');
OUT.scheme3 = main_scheme3_mc_verify_paper();
OUT.savedFigures = [OUT.savedFigures; local_save_and_close(figDir, 'scheme3_')];

local_write_tables(OUT, tableDir);
local_write_summary(OUT, outRoot);
OUT.savedArtifacts = save_experiment_artifacts(outRoot, cfg, OUT, ...
    'Name', 'paper_run_all', ...
    'Tables', local_collect_tables(OUT), ...
    'SaveFigures', false);

assignin('base','paper_run_all_out',OUT);

fprintf('\nPaper experiments finished.\n');
fprintf('Output root: %s\n', outRoot);

end

function saved = local_save_and_close(figDir, prefix)
saved = save_all_open_figures(figDir, prefix);
close all;
end

function tables = local_collect_tables(OUT)
tables = struct();

if isfield(OUT, 'scheme1') && isfield(OUT.scheme1, 'summaryTable')
    tables.scheme1_summary_table = OUT.scheme1.summaryTable;
end
if isfield(OUT, 'geometryFairness')
    tables.geometry_fairness_fixed_footprint = OUT.geometryFairness.fixedFootprintTable;
    tables.geometry_fairness_center_target = OUT.geometryFairness.centerTargetTable;
    tables.geometry_fairness_mean_distance = OUT.geometryFairness.meanDistanceTable;
end
if isfield(OUT.baseline, 'baselineTable')
    tables.baseline_table = OUT.baseline.baselineTable;
end
if isfield(OUT.baseline, 'fairBaselineTable')
    tables.fair_baseline_table = OUT.baseline.fairBaselineTable;
end
if isfield(OUT.baseline, 'familyTable')
    tables.baseline_family_table = OUT.baseline.familyTable;
end
if isfield(OUT.noise, 'rangeTable')
    tables.range_noise_sensitivity = OUT.noise.rangeTable;
end
if isfield(OUT.noise, 'processTable')
    tables.process_noise_sensitivity = OUT.noise.processTable;
end
if isfield(OUT, 'pareto') && isfield(OUT.pareto, 'paretoTable')
    tables.pareto_front = OUT.pareto.paretoTable;
end
if isfield(OUT, 'pareto') && isfield(OUT.pareto, 'targetParetoTable')
    tables.target_feasible_pareto_front = OUT.pareto.targetParetoTable;
end
end

function local_write_tables(OUT, tableDir)
if isfield(OUT, 'scheme1') && isfield(OUT.scheme1, 'summaryTable')
    writetable(OUT.scheme1.summaryTable, fullfile(tableDir, 'scheme1_summary_table.csv'));
end

if isfield(OUT, 'geometryFairness')
    writetable(OUT.geometryFairness.fixedFootprintTable, ...
        fullfile(tableDir, 'geometry_fairness_fixed_footprint.csv'));
    writetable(OUT.geometryFairness.centerTargetTable, ...
        fullfile(tableDir, 'geometry_fairness_center_target.csv'));
    writetable(OUT.geometryFairness.meanDistanceTable, ...
        fullfile(tableDir, 'geometry_fairness_mean_distance.csv'));
end

if isfield(OUT.baseline, 'baselineTable')
    writetable(OUT.baseline.baselineTable, fullfile(tableDir, 'baseline_table.csv'));
end

if isfield(OUT.baseline, 'familyTable')
    writetable(OUT.baseline.familyTable, fullfile(tableDir, 'baseline_family_table.csv'));
end

if isfield(OUT.noise, 'rangeTable')
    writetable(OUT.noise.rangeTable, fullfile(tableDir, 'range_noise_sensitivity.csv'));
end

if isfield(OUT.noise, 'processTable')
    writetable(OUT.noise.processTable, fullfile(tableDir, 'process_noise_sensitivity.csv'));
end
end

function local_write_summary(OUT, outRoot)
summaryPath = fullfile(outRoot, 'paper_experiment_summary.txt');
fid = fopen(summaryPath, 'w');

if fid < 0
    warning('Could not write summary file: %s', summaryPath);
    return;
end

cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'USV-AUV cooperative navigation paper experiment summary\n');
fprintf(fid, 'Generated: %s\n\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));

robust = OUT.baseline.robust;
fprintf(fid, 'Selected robust strategy\n');
fprintf(fid, '  family: %s\n', char(robust.family));
fprintf(fid, '  N: %d\n', robust.N);
fprintf(fid, '  s: %.2f m\n', robust.s);
fprintf(fid, '  beta: %.2f deg\n', robust.beta_deg);
fprintf(fid, '  f_ac: %.3f Hz\n', robust.f_ac);
fprintf(fid, '  f_phys_max: %.3f Hz\n', robust.f_phys_max);
fprintf(fid, '  score: %.4f\n\n', robust.score);

fprintf(fid, 'Suggested manuscript improvements covered by code\n');
fprintf(fid, '  1. Baseline comparison: dead-reckoning and single-USV ranging.\n');
fprintf(fid, '  2. Robust fixed-strategy selection under GNSS degradation.\n');
fprintf(fid, '  3. Parameter sensitivity: range noise and process noise.\n');
fprintf(fid, '  4. Monte Carlo EKF verification against dynamic BCRLB.\n');
fprintf(fid, '  5. Automatic export of figures and CSV tables.\n');
fprintf(fid, '  6. Spatial precision maps showing where each formation family is advantageous.\n');
fprintf(fid, '  7. Geometry fairness diagnostics for fixed footprint, centered target, and fixed mean anchor distance.\n\n');

fprintf(fid, 'Output folders\n');
fprintf(fid, '  figures: %s\n', fullfile(outRoot, 'figures'));
fprintf(fid, '  tables: %s\n', fullfile(outRoot, 'tables'));
if isfield(OUT, 'savedFigures')
    fprintf(fid, '  saved figure files: %d\n', numel(OUT.savedFigures));
end
end
