function OUT = main_scheme3_mc_verify()
% Scheme 3 revised: Monte Carlo / EKF verification among family-best strategies.

close all;
cfg = default_config();

gnssEval = cfg.meas.gnss_sigma_default;

robust = find_global_robust_strategy(cfg, cfg.grid.gnss);
cand = robust.allFamilies;

nC = numel(cand);

mc = cell(nC,1);
labels = strings(nC,1);

for i = 1:nC
    labels(i) = string(cand{i}.family) + "-best";
    fprintf('Running MC for %s...\n', labels(i));
    mc{i} = run_mc_ekf(cand{i}, gnssEval, cfg);
end

% Identify robust index.
robustIdx = 1;
for i = 1:nC
    if strcmpi(string(cand{i}.family), string(robust.family))
        robustIdx = i;
        break;
    end
end

OUT.robust = robust;
OUT.candidates = cand;
OUT.mc = mc;
OUT.labels = labels;
OUT.robustIdx = robustIdx;

% Strategy table
Role = strings(nC,1);
Family = strings(nC,1);
Ncol = zeros(nC,1);
Scol = zeros(nC,1);
Bcol = zeros(nC,1);
Fcol = zeros(nC,1);
Fphys = zeros(nC,1);
Cost = zeros(nC,1);
FinalMC = zeros(nC,1);
FinalBCRLB = zeros(nC,1);
FinalMC_CI_L = zeros(nC,1);
FinalMC_CI_U = zeros(nC,1);
ConsistencyRatio = zeros(nC,1);

for i = 1:nC
    if i == robustIdx
        Role(i) = "robust-selected";
    else
        Role(i) = "family-best";
    end

    Family(i) = string(cand{i}.family);
    Ncol(i) = cand{i}.N;
    Scol(i) = cand{i}.s;
    Bcol(i) = cand{i}.beta_deg;
    Fcol(i) = cand{i}.f_ac;
    Fphys(i) = cand{i}.f_phys_max;
    Cost(i) = cand{i}.cost;
    FinalMC(i) = mc{i}.final_rmse;
    FinalBCRLB(i) = mc{i}.bound_rmse;
    if isfield(mc{i}, 'final_rmse_ci95')
        FinalMC_CI_L(i) = mc{i}.final_rmse_ci95(1);
        FinalMC_CI_U(i) = mc{i}.final_rmse_ci95(2);
    else
        FinalMC_CI_L(i) = nan;
        FinalMC_CI_U(i) = nan;
    end
    ConsistencyRatio(i) = FinalMC(i) / max(FinalBCRLB(i), eps);
end

Tbl = table(Role,Family,Ncol,Scol,Bcol,Fcol,Fphys,Cost, ...
    FinalMC,FinalMC_CI_L,FinalMC_CI_U,FinalBCRLB,ConsistencyRatio);

assignin('base','scheme3_strategy_table',Tbl);
disp('===== Scheme 3 revised strategy table =====');
disp(Tbl);

figure('Color','w','Position',[60 60 1450 850]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

% (a) Time RMSE
nexttile; hold on; grid on; box on;
C = lines(nC);
tt = (1:numel(mc{1}.rmse_time)) * cfg.target.dt;

for i = 1:nC
    plot(tt, mc{i}.rmse_time, '-', 'LineWidth', 2, ...
        'Color', C(i,:), ...
        'DisplayName', sprintf('%s MC', labels(i)));

    plot(tt, mc{i}.bound_time, '--', 'LineWidth', 1.4, ...
        'Color', C(i,:), ...
        'DisplayName', sprintf('%s BCRLB', labels(i)));
end

xlabel('Time / s');
ylabel('Position RMSE / m');
title(sprintf('Scheme 3(a) MC RMSE vs BCRLB, \\sigma_{GNSS}=%.1f m', gnssEval));
legend('Location','best');

% (b) Final metrics with categorical x-axis
nexttile; hold on; grid on; box on;
catLabels = categorical(cellstr(labels));
catLabels = reordercats(catLabels, cellstr(labels));

Y = [FinalMC, FinalBCRLB];
bar(catLabels, Y);
if all(isfinite(FinalMC_CI_L))
    x = 1:nC;
    errLow = FinalMC - FinalMC_CI_L;
    errHigh = FinalMC_CI_U - FinalMC;
    errorbar(x - 0.15, FinalMC, errLow, errHigh, ...
        'k.', 'LineWidth', 1.2, 'HandleVisibility','off');
end
ylabel('Metric / m');
legend({'MC final RMSE','final BCRLB'},'Location','northwest');
title('Scheme 3(b) Final RMSE and BCRLB by strategy');

% (c) All final error clouds and ellipses
nexttile; hold on; grid on; box on; axis equal;
local_plot_all_error_ellipses(mc, cand, labels, robustIdx, C);
xlabel('x error / m');
ylabel('y error / m');
title('Scheme 3(c) Final error clouds and BCRLB ellipses');

% (d) Selected strategy geometries
nexttile; hold on; grid on; box on; axis equal;
local_plot_strategy_geometries(cand, robustIdx, C);
xlabel('x / m');
ylabel('y / m');
title('Scheme 3(d) Family-best geometries, robust highlighted');

sgtitle('Scheme 3 revised  Monte Carlo / EKF verification among family-best strategies');

end

function local_plot_all_error_ellipses(mc, cand, labels, robustIdx, C)
nC = numel(mc);

for i = 1:nC
    isRobust = i == robustIdx;
    lw = 1.7 + 1.2 * isRobust;
    alpha = 0.18 + 0.12 * isRobust;

    scatter(mc{i}.scatter(:,1), mc{i}.scatter(:,2), 16, ...
        'filled', ...
        'MarkerFaceColor', C(i,:), ...
        'MarkerFaceAlpha', alpha, ...
        'MarkerEdgeAlpha', 0.10, ...
        'DisplayName', sprintf('%s MC', labels(i)));

    plot_error_ellipse([0;0], mc{i}.Pxy_bound, ...
        'Color', C(i,:), ...
        'LineWidth', lw, ...
        'DisplayName', sprintf('%s BCRLB ellipse', labels(i)));
end

scatter(0,0,85,'p', ...
    'MarkerFaceColor',[0.85 0.05 0.05], ...
    'MarkerEdgeColor','k', ...
    'DisplayName','zero error');

legend('Location','bestoutside');
text(0.02,0.98, sprintf('Robust selected: %s', char(cand{robustIdx}.family)), ...
    'Units','normalized', ...
    'VerticalAlignment','top', ...
    'BackgroundColor','w', ...
    'Margin',5);
end

function local_plot_strategy_geometries(cand, robustIdx, C)
nC = numel(cand);

for i = 1:nC
    A = cand{i}.anchors;
    isRobust = i == robustIdx;
    lw = 1.5 + 1.2 * isRobust;
    ms = 6 + 2 * isRobust;

    plot(A(:,1), A(:,2), 'o-', ...
        'Color', C(i,:), ...
        'MarkerFaceColor', C(i,:), ...
        'MarkerSize', ms, ...
        'LineWidth', lw, ...
        'DisplayName', sprintf('%s%s', char(cand{i}.family), local_role_suffix(isRobust)));
end

scatter(0,0,80,'p', ...
    'MarkerFaceColor',[0.85 0.05 0.05], ...
    'MarkerEdgeColor','k', ...
    'DisplayName','formation center');
legend('Location','best');
end

function s = local_role_suffix(isRobust)
if isRobust
    s = ' (robust)';
else
    s = '';
end
end
