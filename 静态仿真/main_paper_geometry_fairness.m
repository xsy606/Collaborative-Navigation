function OUT = main_paper_geometry_fairness(mode)
%MAIN_PAPER_GEOMETRY_FAIRNESS Diagnose wedge/polygon comparison fairness.
%
% Experiment A fixes formation footprint.
% Experiment B places the target at the formation center.
% Experiment C fixes mean anchor distance to the AUV.

close all;
paper_style();

if nargin < 1 || isempty(mode)
    cfg = default_config('paper');
else
    cfg = default_config(mode);
end

families = {'line','wedge','polygon'};
N = cfg.example.N;
beta_deg = cfg.example.beta_deg;
sigma_gnss = cfg.meas.gnss_sigma_default;

switch lower(cfg.run.mode)
    case 'paper'
        footprintGrid = 200:50:850;
        avgStep = 50;
    otherwise
        footprintGrid = 200:100:800;
        avgStep = 100;
end

pNom = cfg.target.nominal_state(1:2);
avgMin = ceil((norm(pNom) + 40) / avgStep) * avgStep;
avgGrid = avgMin:avgStep:900;

OUT = struct();
OUT.cfg = cfg;
OUT.footprintGrid = footprintGrid;
OUT.avgDistanceGrid = avgGrid;
OUT.fixedFootprintTable = local_experiment_fixed_footprint( ...
    cfg, families, N, beta_deg, sigma_gnss, footprintGrid);
centerFamilies = {'wedge','polygon'};
centerFamilyName = {'Wedge','Polygon'};
OUT.centerTargetTable = local_experiment_center_target( ...
    cfg, centerFamilies, N, beta_deg, sigma_gnss, median(footprintGrid));
OUT.meanDistanceTable = local_experiment_mean_distance( ...
    cfg, families, N, beta_deg, sigma_gnss, avgGrid);

assignin('base','paper_geometry_fairness_out',OUT);
assignin('base','paper_geometry_fairness_fixed_footprint',OUT.fixedFootprintTable);
assignin('base','paper_geometry_fairness_center_target',OUT.centerTargetTable);
assignin('base','paper_geometry_fairness_mean_distance',OUT.meanDistanceTable);

disp('===== Geometry fairness A: fixed footprint =====');
disp(local_best_by_constraint(OUT.fixedFootprintTable, 'footprint'));
disp('===== Geometry fairness B: centered target =====');
disp(OUT.centerTargetTable);
disp('===== Geometry fairness C: fixed mean anchor distance =====');
disp(local_best_by_constraint(OUT.meanDistanceTable, 'mean_anchor_distance'));

local_plot_fixed_footprint(OUT.fixedFootprintTable, families, cfg);
local_plot_center_target(OUT.centerTargetTable, centerFamilies, centerFamilyName, cfg);
local_plot_mean_distance(OUT.meanDistanceTable, families, cfg);

end

function T = local_experiment_fixed_footprint(cfg, families, N, beta_deg, sigma_gnss, footprintGrid)
nRows = numel(footprintGrid) * numel(families);
[Family, Constraint, FCommon, Footprint, MeanDist, RMSE, AxisRatio, CondNum, Area95, Fphys] = ...
    local_prealloc(nRows);

row = 0;
for iF = 1:numel(footprintGrid)
    foot = footprintGrid(iF);
    anchorsSet = cell(numel(families),1);
    for iFam = 1:numel(families)
        anchorsSet{iFam} = scale_formation_to_footprint( ...
            local_base_anchors(families{iFam}, N, beta_deg), foot);
    end

    fCommon = local_common_feasible_rate(anchorsSet, cfg);
    for iFam = 1:numel(families)
        row = row + 1;
        rec = evaluate_anchor_geometry(families{iFam}, anchorsSet{iFam}, ...
            beta_deg, fCommon, sigma_gnss, cfg, 'StoreSeries', false);

        [Family, Constraint, FCommon, Footprint, MeanDist, RMSE, AxisRatio, CondNum, Area95, Fphys] = ...
            local_fill(row, Family, Constraint, FCommon, Footprint, MeanDist, RMSE, ...
            AxisRatio, CondNum, Area95, Fphys, rec, families{iFam}, foot, fCommon, cfg);
    end
end

T = table(Family, Constraint, FCommon, Footprint, MeanDist, RMSE, ...
    AxisRatio, CondNum, Area95, Fphys, ...
    'VariableNames', {'family','footprint_setting','f_common','footprint', ...
    'mean_anchor_distance','rmse_xy','axis_ratio','condnum','area95','f_phys_max'});
end

function T = local_experiment_center_target(cfg, families, N, beta_deg, sigma_gnss, footprint)
caseName = ["center-stationary"; "center-moving"];
nRows = numel(caseName) * numel(families);
Family = strings(nRows,1);
CaseName = strings(nRows,1);
FCommon = zeros(nRows,1);
Footprint = zeros(nRows,1);
MeanDist = zeros(nRows,1);
RMSE = zeros(nRows,1);
AxisRatio = zeros(nRows,1);
CondNum = zeros(nRows,1);
Area95 = zeros(nRows,1);
Fphys = zeros(nRows,1);

row = 0;
for iCase = 1:numel(caseName)
    cfgCase = cfg;
    if iCase == 1
        cfgCase.target.nominal_state = [0; 0; 0; 0];
    else
        cfgCase.target.nominal_state = [0; 0; cfg.target.nominal_state(3:4)];
    end

    anchorsSet = cell(numel(families),1);
    for iFam = 1:numel(families)
        anchorsSet{iFam} = scale_formation_to_footprint( ...
            local_base_anchors(families{iFam}, N, beta_deg), footprint);
    end
    fCommon = local_common_feasible_rate(anchorsSet, cfgCase);

    for iFam = 1:numel(families)
        row = row + 1;
        rec = evaluate_anchor_geometry(families{iFam}, anchorsSet{iFam}, ...
            beta_deg, fCommon, sigma_gnss, cfgCase, 'StoreSeries', false);

        Family(row) = string(families{iFam});
        CaseName(row) = caseName(iCase);
        FCommon(row) = fCommon;
        Footprint(row) = rec.footprint;
        MeanDist(row) = rec.mean_anchor_distance;
        RMSE(row) = rec.rmse_xy;
        AxisRatio(row) = rec.major95 / max(rec.minor95, eps);
        CondNum(row) = rec.condnum;
        Area95(row) = rec.area95;
        Fphys(row) = rec.f_phys_max;
    end
end

T = table(Family, CaseName, FCommon, Footprint, MeanDist, RMSE, ...
    AxisRatio, CondNum, Area95, Fphys, ...
    'VariableNames', {'family','case','f_common','footprint', ...
    'mean_anchor_distance','rmse_xy','axis_ratio','condnum','area95','f_phys_max'});
end

function T = local_experiment_mean_distance(cfg, families, N, beta_deg, sigma_gnss, avgGrid)
nRows = numel(avgGrid) * numel(families);
[Family, Constraint, FCommon, Footprint, MeanDist, RMSE, AxisRatio, CondNum, Area95, Fphys] = ...
    local_prealloc(nRows);

row = 0;
p = cfg.target.nominal_state(1:2);
for iA = 1:numel(avgGrid)
    avgDist = avgGrid(iA);
    anchorsSet = cell(numel(families),1);
    for iFam = 1:numel(families)
        anchorsSet{iFam} = scale_formation_to_mean_distance( ...
            local_base_anchors(families{iFam}, N, beta_deg), p, avgDist);
    end

    fCommon = local_common_feasible_rate(anchorsSet, cfg);
    for iFam = 1:numel(families)
        row = row + 1;
        rec = evaluate_anchor_geometry(families{iFam}, anchorsSet{iFam}, ...
            beta_deg, fCommon, sigma_gnss, cfg, 'StoreSeries', false);

        [Family, Constraint, FCommon, Footprint, MeanDist, RMSE, AxisRatio, CondNum, Area95, Fphys] = ...
            local_fill(row, Family, Constraint, FCommon, Footprint, MeanDist, RMSE, ...
            AxisRatio, CondNum, Area95, Fphys, rec, families{iFam}, avgDist, fCommon, cfg);
    end
end

T = table(Family, Constraint, FCommon, Footprint, MeanDist, RMSE, ...
    AxisRatio, CondNum, Area95, Fphys, ...
    'VariableNames', {'family','mean_distance_setting','f_common','footprint', ...
    'mean_anchor_distance','rmse_xy','axis_ratio','condnum','area95','f_phys_max'});
end

function A = local_base_anchors(fam, N, beta_deg)
param = struct('beta_deg', beta_deg, 'rot_deg', 0);
if strcmpi(fam, 'polygon')
    param.rot_deg = 180 / N;
end
A = build_formation(fam, N, 1, param);
end

function fCommon = local_common_feasible_rate(anchorsSet, cfg)
fPhys = inf(numel(anchorsSet),1);
for i = 1:numel(anchorsSet)
    fPhys(i) = acoustic_physical_limit(anchorsSet{i}, cfg);
end
fCommon = min(cfg.example.f, 0.95 * min(fPhys));
end

function [Family, Constraint, FCommon, Footprint, MeanDist, RMSE, AxisRatio, CondNum, Area95, Fphys] = ...
    local_prealloc(nRows)
Family = strings(nRows,1);
Constraint = zeros(nRows,1);
FCommon = zeros(nRows,1);
Footprint = zeros(nRows,1);
MeanDist = zeros(nRows,1);
RMSE = zeros(nRows,1);
AxisRatio = zeros(nRows,1);
CondNum = zeros(nRows,1);
Area95 = zeros(nRows,1);
Fphys = zeros(nRows,1);
end

function [Family, Constraint, FCommon, Footprint, MeanDist, RMSE, AxisRatio, CondNum, Area95, Fphys] = ...
    local_fill(row, Family, Constraint, FCommon, Footprint, MeanDist, RMSE, ...
    AxisRatio, CondNum, Area95, Fphys, rec, fam, constraintVal, fCommon, cfg)
Family(row) = string(fam);
Constraint(row) = constraintVal;
FCommon(row) = fCommon;
Footprint(row) = rec.footprint;
MeanDist(row) = formation_mean_anchor_distance(rec.anchors, cfg.target.nominal_state(1:2));
RMSE(row) = rec.rmse_xy;
AxisRatio(row) = rec.major95 / max(rec.minor95, eps);
CondNum(row) = rec.condnum;
Area95(row) = rec.area95;
Fphys(row) = rec.f_phys_max;
end

function Tbest = local_best_by_constraint(T, constraintName)
u = unique(T.(constraintName));
rows = false(height(T),1);
for i = 1:numel(u)
    idx = find(abs(T.(constraintName) - u(i)) < 1e-9);
    [~, j] = min(T.rmse_xy(idx));
    rows(idx(j)) = true;
end
Tbest = T(rows,:);
end

function local_plot_fixed_footprint(T, families, cfg)
new_paper_figure('Paper_geometry_fairness_A_fixed_footprint', [90 90 900 620]);
hold on;
for iFam = 1:numel(families)
    fam = families{iFam};
    st = family_style(fam);
    idx = strcmpi(T.family, fam);
    plot(T.footprint_setting(idx), T.rmse_xy(idx), '-o', ...
        'Color', st.color, 'MarkerFaceColor', st.color, ...
        'LineWidth', 2.1, 'MarkerSize', 5.5, ...
        'DisplayName', st.name);
end
xlabel('Fixed formation footprint / m');
ylabel('Horizontal RMSE lower bound / m');
title('Experiment A: fixed footprint fairness test');
ylim([0, max([T.rmse_xy; cfg.requirement.rmse_xy])*1.15]);
plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE');
legend('Location','northeast');
apply_axis_style(gca);
end

function local_plot_center_target(T, families, familyName, cfg)
new_paper_figure('Paper_geometry_fairness_B_center_target', [120 120 980 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

cases = unique(T.case, 'stable');
Yrmse = nan(numel(cases), numel(families));
Yratio = nan(numel(cases), numel(families));
for iCase = 1:numel(cases)
    for iFam = 1:numel(families)
        idx = T.case == cases(iCase) & strcmpi(T.family, families{iFam});
        Yrmse(iCase,iFam) = T.rmse_xy(idx);
        Yratio(iCase,iFam) = T.axis_ratio(idx);
    end
end

nexttile; hold on; box on; grid on;
b = bar(categorical(cellstr(cases)), Yrmse, 0.72);
local_color_bars(b, families);
ylabel('Horizontal RMSE lower bound / m');
title('Centered target RMSE');
ylim([0, max([Yrmse(:); cfg.requirement.rmse_xy])*1.18]);
plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE');
legend(familyName, 'Location','northwest');
apply_axis_style(gca);

nexttile; hold on; box on; grid on;
b = bar(categorical(cellstr(cases)), Yratio, 0.72);
local_color_bars(b, families);
ylabel('95% ellipse axis ratio');
title('Centered target isotropy');
yline(1, ':', 'isotropic', 'Color',[0.30 0.30 0.30], 'LineWidth',1.2);
legend(familyName, 'Location','northwest');
apply_axis_style(gca);
end

function local_plot_mean_distance(T, families, cfg)
new_paper_figure('Paper_geometry_fairness_C_fixed_mean_distance', [150 150 900 620]);
hold on;
for iFam = 1:numel(families)
    fam = families{iFam};
    st = family_style(fam);
    idx = strcmpi(T.family, fam);
    plot(T.mean_distance_setting(idx), T.rmse_xy(idx), '-o', ...
        'Color', st.color, 'MarkerFaceColor', st.color, ...
        'LineWidth', 2.1, 'MarkerSize', 5.5, ...
        'DisplayName', st.name);
end
xlabel('Fixed mean horizontal anchor distance / m');
ylabel('Horizontal RMSE lower bound / m');
title('Experiment C: fixed mean anchor-distance fairness test');
ylim([0, max([T.rmse_xy; cfg.requirement.rmse_xy])*1.15]);
plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE');
legend('Location','northeast');
apply_axis_style(gca);
end

function local_color_bars(b, families)
for i = 1:numel(b)
    st = family_style(families{i});
    b(i).FaceColor = st.color;
    b(i).FaceAlpha = 0.88;
end
end
