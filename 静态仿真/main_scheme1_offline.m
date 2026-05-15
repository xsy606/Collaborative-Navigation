function OUT = main_scheme1_offline(mode)
%MAIN_SCHEME1_OFFLINE Multi-scenario offline design-rule analysis.
%
% The paper grid is relatively large. This implementation enumerates each
% family/GNSS design table once, stores only compact metrics, and derives
% all rule curves from that table. It avoids the previous persistent cache
% of full BCRLB records, which could exhaust MATLAB memory in paper mode.

close all;
paper_style();

if nargin < 1 || isempty(mode)
    cfg = default_config();
else
    cfg = default_config(mode);
end

gnssGrid = cfg.grid.gnss;
families = {'line','wedge','polygon'};
scenarioStates = local_build_scenarios(cfg, cfg.scheme1);

OUT = struct();
OUT.cfg = cfg;
OUT.scenarioStates = scenarioStates;
OUT.designTables = struct();

for iFam = 1:numel(families)
    fam = families{iFam};
    OUT.(fam) = local_init_family_out(gnssGrid);
end

for iFam = 1:numel(families)
    fam = families{iFam};

    for ig = 1:numel(gnssGrid)
        sg = gnssGrid(ig);
        fprintf('Scheme 1: family=%s, sigma_GNSS=%.2f m (%d/%d)\n', ...
            fam, sg, ig, numel(gnssGrid));

        D = local_enumerate_designs(fam, cfg, sg, scenarioStates);
        OUT.designTables.(fam){ig} = D;

        ok = D.is_feasible & D.rmse_xy <= cfg.requirement.rmse_xy;
        OUT.(fam).minS(ig) = local_min_value(D.s, ok);
        OUT.(fam).minF(ig) = local_min_value(D.f_ac, ok);
        OUT.(fam).minN(ig) = local_min_value(D.N, ok);

        best = local_best_design_from_table(fam, D, cfg);
        OUT.(fam).bestDesign{ig} = best;

        if isfield(best, 'N') && isfinite(best.rmse_xy)
            imp = local_importance_from_table(best, D, cfg);
            OUT.(fam).impS(ig) = imp.s;
            OUT.(fam).impF(ig) = imp.f;
            OUT.(fam).impN(ig) = imp.N;
        end
    end
end

[impS, impF, impN] = local_mean_importance(OUT, gnssGrid, families);
OUT.meanImportance.spacing = impS;
OUT.meanImportance.rate = impF;
OUT.meanImportance.count = impN;

Tbl = local_summary_table(OUT, gnssGrid, families);
OUT.summaryTable = Tbl;

assignin('base','scheme1_out',OUT);
assignin('base','scheme1_summary_table',Tbl);

disp('===== Scheme 1 sampled summary table =====');
disp(Tbl);

local_plot_scheme1(OUT, gnssGrid, families);

end

function S = local_init_family_out(gnssGrid)
S.minS = nan(size(gnssGrid));
S.minF = nan(size(gnssGrid));
S.minN = nan(size(gnssGrid));
S.impS = nan(size(gnssGrid));
S.impF = nan(size(gnssGrid));
S.impN = nan(size(gnssGrid));
S.bestDesign = cell(size(gnssGrid));
end

function states = local_build_scenarios(cfg, scfg)
x0 = cfg.target.nominal_state(1);
y0 = cfg.target.nominal_state(2);
r0 = hypot(x0, y0);
theta0 = atan2d(y0, x0);

angles = theta0 + scfg.angle_offsets_deg;
states = zeros(4, numel(angles));

for i = 1:numel(angles)
    states(1,i) = r0 * cosd(angles(i));
    states(2,i) = r0 * sind(angles(i));

    if scfg.keep_nominal_velocity
        states(3:4,i) = cfg.target.nominal_state(3:4);
    end
end
end

function betaSet = local_beta_set(fam, cfg)
if strcmpi(fam, 'wedge')
    betaSet = cfg.grid.beta_deg;
else
    betaSet = cfg.example.beta_deg;
end
end

function D = local_enumerate_designs(fam, cfg, sigma_gnss, states)
betaSet = local_beta_set(fam, cfg);
nRows = numel(cfg.grid.N) * numel(cfg.grid.s) * numel(betaSet) * numel(cfg.acoustic.f_grid);

Family = strings(nRows,1);
Ncol = zeros(nRows,1);
Scol = zeros(nRows,1);
Beta = zeros(nRows,1);
Fac = zeros(nRows,1);
Sigma = zeros(nRows,1);
RMSE = inf(nRows,1);
Area95 = inf(nRows,1);
Major95 = inf(nRows,1);
Minor95 = inf(nRows,1);
CondNum = inf(nRows,1);
Fphys = zeros(nRows,1);
Cost = zeros(nRows,1);
Feasible = false(nRows,1);
WorstScenario = zeros(nRows,1);

row = 0;
for N = cfg.grid.N
    for s = cfg.grid.s
        for beta = betaSet
            for f = cfg.acoustic.f_grid
                row = row + 1;
                rec = local_worst_eval_compact(fam, N, s, beta, f, sigma_gnss, cfg, states);

                Family(row) = string(fam);
                Ncol(row) = N;
                Scol(row) = s;
                Beta(row) = beta;
                Fac(row) = f;
                Sigma(row) = sigma_gnss;
                RMSE(row) = rec.rmse_xy;
                Area95(row) = rec.area95;
                Major95(row) = rec.major95;
                Minor95(row) = rec.minor95;
                CondNum(row) = rec.condnum;
                Fphys(row) = rec.f_phys_max;
                Cost(row) = rec.cost;
                Feasible(row) = rec.is_feasible;
                WorstScenario(row) = rec.worst_scenario_index;
            end
        end
    end
end

D = table(Family,Ncol,Scol,Beta,Fac,Sigma,RMSE,Area95,Major95,Minor95, ...
    CondNum,Fphys,Cost,Feasible,WorstScenario, ...
    'VariableNames', {'family','N','s','beta_deg','f_ac','sigma_gnss','rmse_xy', ...
    'area95','major95','minor95','condnum','f_phys_max','cost', ...
    'is_feasible','worst_scenario_index'});
end

function recAgg = local_worst_eval_compact(fam, N, s, beta, f, sigma_gnss, cfg, states)
anchors = local_design_anchors(fam, N, s, beta);
costVal = family_cost(fam, anchors, N, f, cfg);

minFphys = inf;
for i = 1:size(states, 2)
    cfgi = cfg;
    cfgi.target.nominal_state = states(:,i);
    minFphys = min(minFphys, acoustic_physical_limit(anchors, cfgi));
end

recAgg = struct();
recAgg.family = string(fam);
recAgg.N = N;
recAgg.s = s;
recAgg.beta_deg = beta;
recAgg.f_ac = f;
recAgg.sigma_gnss = sigma_gnss;
recAgg.anchors = anchors;
recAgg.Pxy = nan(2,2);
recAgg.rmse_xy = inf;
recAgg.major95 = inf;
recAgg.minor95 = inf;
recAgg.area95 = inf;
recAgg.condnum = inf;
recAgg.f_phys_max = minFphys;
recAgg.is_feasible = false;
recAgg.cost = costVal;
recAgg.worst_scenario_index = 1;

if f > minFphys + 1e-12
    return;
end

worstRMSE = -inf;
allFeasible = true;
for i = 1:size(states, 2)
    cfgi = cfg;
    cfgi.target.nominal_state = states(:,i);
    rec = evaluate_design(fam, N, s, beta, f, sigma_gnss, cfgi, ...
        'StoreSeries', false);

    allFeasible = allFeasible && rec.is_feasible;
    val = rec.rmse_xy;
    if ~isfinite(val)
        val = inf;
    end

    if val > worstRMSE
        worstRMSE = val;
        recAgg = rec;
        recAgg.worst_scenario_index = i;
    end
end

recAgg.rmse_xy = worstRMSE;
recAgg.f_phys_max = minFphys;
recAgg.is_feasible = allFeasible;
recAgg.cost = costVal;
end

function anchors = local_design_anchors(fam, N, s, beta)
param = struct();
if strcmpi(fam, 'wedge')
    param.beta_deg = beta;
elseif strcmpi(fam, 'polygon')
    param.rot_deg = 180 / N;
end
anchors = build_formation(fam, N, s, param);
end

function v = local_min_value(x, mask)
if any(mask)
    v = min(x(mask));
else
    v = nan;
end
end

function best = local_best_design_from_table(fam, D, cfg)
if isempty(D)
    best = struct();
    return;
end

rm = D.rmse_xy(:) / cfg.requirement.rmse_xy;
cost = D.cost(:);
idxFeas = find(D.is_feasible & isfinite(rm));

if isempty(idxFeas)
    idxCostNorm = find(isfinite(cost));
else
    idxCostNorm = idxFeas;
end

if isempty(idxCostNorm)
    best = struct();
    return;
end

cmin = min(cost(idxCostNorm));
cmax = max(cost(idxCostNorm));
if abs(cmax - cmin) < 1e-12
    costNorm = zeros(size(cost));
else
    costNorm = (cost - cmin) ./ (cmax - cmin);
end

score = cfg.scheme1.best_score_worst * rm + cfg.scheme1.best_score_cost * costNorm;
score(~D.is_feasible) = score(~D.is_feasible) + 10;
score(~isfinite(score)) = inf;

if any(D.is_feasible & isfinite(score))
    idxPool = find(D.is_feasible & isfinite(score));
else
    idxPool = find(isfinite(score));
end

if isempty(idxPool)
    best = struct();
    return;
end

[~, ii] = min(score(idxPool));
idx = idxPool(ii);
best = local_table_row_to_struct(fam, D(idx,:));
best.score = score(idx);
best.norm_rmse = rm(idx);
best.cost_norm = costNorm(idx);
end

function imp = local_importance_from_table(best, D, cfg)
baseVal = max(best.rmse_xy, 1e-9);

Es = local_elasticity(@(x) local_lookup_rmse(D, best.N, x, best.beta_deg, best.f_ac), ...
    cfg.grid.s, best.s, baseVal);
Ef = local_elasticity(@(x) local_lookup_rmse(D, best.N, best.s, best.beta_deg, x), ...
    cfg.acoustic.f_grid, best.f_ac, baseVal);
EN = local_elasticity(@(x) local_lookup_rmse(D, x, best.s, best.beta_deg, best.f_ac), ...
    cfg.grid.N, best.N, baseVal);

v = [Es, Ef, EN];
v(~isfinite(v)) = 0;

if sum(v) < 1e-12
    v = [1 1 1] / 3;
else
    v = v / sum(v);
end

imp.s = v(1);
imp.f = v(2);
imp.N = v(3);
end

function y = local_lookup_rmse(D, N, s, beta, f)
mask = D.N == N & abs(D.s - s) < 1e-12 & ...
    abs(D.beta_deg - beta) < 1e-12 & abs(D.f_ac - f) < 1e-12;

if any(mask)
    y = D.rmse_xy(find(mask, 1));
else
    y = nan;
end
end

function E = local_elasticity(fun, grid, x0, baseVal)
idx = find(abs(grid - x0) < 1e-12, 1);

if isempty(idx)
    E = nan;
    return;
end

if idx > 1 && idx < numel(grid)
    xL = grid(idx-1);
    xR = grid(idx+1);
    yL = max(fun(xL), 1e-9);
    yR = max(fun(xR), 1e-9);
    E = abs((log(yR)-log(yL)) / (log(xR)-log(xL)));
elseif idx > 1
    xL = grid(idx-1);
    yL = max(fun(xL), 1e-9);
    y0 = max(baseVal, 1e-9);
    E = abs((log(y0)-log(yL)) / (log(x0)-log(xL)));
elseif idx < numel(grid)
    xR = grid(idx+1);
    yR = max(fun(xR), 1e-9);
    y0 = max(baseVal, 1e-9);
    E = abs((log(yR)-log(y0)) / (log(xR)-log(x0)));
else
    E = nan;
end
end

function best = local_table_row_to_struct(fam, row)
best = struct();
best.family = string(fam);
best.N = row.N;
best.s = row.s;
best.beta_deg = row.beta_deg;
best.f_ac = row.f_ac;
best.sigma_gnss = row.sigma_gnss;
best.anchors = local_design_anchors(fam, row.N, row.s, row.beta_deg);
best.Pxy = nan(2,2);
best.rmse_xy = row.rmse_xy;
best.major95 = row.major95;
best.minor95 = row.minor95;
best.area95 = row.area95;
best.condnum = row.condnum;
best.f_phys_max = row.f_phys_max;
best.is_feasible = row.is_feasible;
best.cost = row.cost;
best.worst_scenario_index = row.worst_scenario_index;

end

function [impS, impF, impN] = local_mean_importance(OUT, gnssGrid, families)
impS = nan(size(gnssGrid));
impF = nan(size(gnssGrid));
impN = nan(size(gnssGrid));

for ig = 1:numel(gnssGrid)
    vs = [];
    vf = [];
    vn = [];

    for iFam = 1:numel(families)
        fam = families{iFam};
        if isfinite(OUT.(fam).impS(ig)), vs(end+1) = OUT.(fam).impS(ig); end %#ok<AGROW>
        if isfinite(OUT.(fam).impF(ig)), vf(end+1) = OUT.(fam).impF(ig); end %#ok<AGROW>
        if isfinite(OUT.(fam).impN(ig)), vn(end+1) = OUT.(fam).impN(ig); end %#ok<AGROW>
    end

    if ~isempty(vs), impS(ig) = mean(vs); end
    if ~isempty(vf), impF(ig) = mean(vf); end
    if ~isempty(vn), impN(ig) = mean(vn); end
end
end

function Tbl = local_summary_table(OUT, gnss, families)
idxSample = unique(round(linspace(1, numel(gnss), min(6, numel(gnss)))));
rows = [];

for i = 1:numel(families)
    fam = families{i};

    for k = idxSample
        b = OUT.(fam).bestDesign{k};

        if isempty(b) || ~isstruct(b) || ~isfield(b,'N')
            continue;
        end

        one.family = string(fam);
        one.sigma_gnss = gnss(k);
        one.N = b.N;
        one.s = b.s;
        one.beta_deg = b.beta_deg;
        one.f_ac = b.f_ac;
        one.f_phys_max = b.f_phys_max;
        one.worst_rmse = b.rmse_xy;
        one.cost = b.cost;
        one.is_feasible = b.is_feasible;

        rows = [rows; struct2table(one)]; %#ok<AGROW>
    end
end

if isempty(rows)
    Tbl = table();
else
    Tbl = rows;
end
end

function local_plot_scheme1(OUT, gnssGrid, families)
pal = paper_palette();
new_paper_figure('Scheme1_offline_design_rules', [60 60 1320 840]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

nexttile; hold on; grid on; box on;
for iFam = 1:numel(families)
    fam = families{iFam};
    st = family_style(fam);
    plot(gnssGrid, OUT.(fam).minS, '-o', ...
        'Color', st.color, 'MarkerFaceColor', st.color, ...
        'MarkerSize', 5, 'LineWidth', 2, 'DisplayName', st.name);
end
xlabel('\sigma_{GNSS} / m');
ylabel('Minimum spacing s / m');
title('Scheme 1(a) Minimum spacing');
legend('Location','northwest');
apply_axis_style(gca);

nexttile; hold on; grid on; box on;
for iFam = 1:numel(families)
    fam = families{iFam};
    st = family_style(fam);
    plot(gnssGrid, OUT.(fam).minF, '-o', ...
        'Color', st.color, 'MarkerFaceColor', st.color, ...
        'MarkerSize', 5, 'LineWidth', 2, 'DisplayName', st.name);
end
xlabel('\sigma_{GNSS} / m');
ylabel('Minimum acoustic rate / Hz');
title('Scheme 1(b) Minimum acoustic update rate');
legend('Location','northwest');
apply_axis_style(gca);

nexttile; hold on; grid on; box on;
for iFam = 1:numel(families)
    fam = families{iFam};
    st = family_style(fam);
    stairs(gnssGrid, OUT.(fam).minN, ...
        'Color', st.color, 'LineWidth', 2, 'DisplayName', st.name);
end
xlabel('\sigma_{GNSS} / m');
ylabel('Minimum number of USVs');
title('Scheme 1(c) Minimum ship count');
legend('Location','northwest');
apply_axis_style(gca);

nexttile; hold on; grid on; box on;
plot(gnssGrid, OUT.meanImportance.spacing, '-o', ...
    'Color', pal.navy, 'MarkerFaceColor', pal.navy, ...
    'LineWidth', 2, 'DisplayName','spacing s');
plot(gnssGrid, OUT.meanImportance.rate, '-s', ...
    'Color', pal.green, 'MarkerFaceColor', pal.green, ...
    'LineWidth', 2, 'DisplayName','rate f');
plot(gnssGrid, OUT.meanImportance.count, '-^', ...
    'Color', pal.orange, 'MarkerFaceColor', pal.orange, ...
    'LineWidth', 2, 'DisplayName','count N');
xlabel('\sigma_{GNSS} / m');
ylabel('Normalized local importance');
title('Scheme 1(d) Variable importance');
legend('Location','best');
apply_axis_style(gca);

sgtitle('Scheme 1  Multi-scenario offline design-rule analysis');
end
