function OUT = main_scheme3_mc_verify_paper(mode)
%MAIN_SCHEME3_MC_VERIFY_PAPER
% Paper-style Scheme 3: separate windows for MC/BCRLB verification.

close all;
paper_style();
if nargin < 1 || isempty(mode)
    mode = 'paper';
end
cfg = default_config(mode);

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

% ==============================================================
% Scheme3 a: time RMSE
% ==============================================================
new_paper_figure('Scheme3_time_RMSE', [90 90 900 640]);
hold on;

tt = (1:numel(mc{1}.rmse_time)) * cfg.target.dt;

for i = 1:nC
    fam = char(cand{i}.family);
    st = family_style(fam);

    plot(tt, mc{i}.rmse_time, ...
        '-', ...
        'Color', st.color, ...
        'LineWidth', 2.3, ...
        'DisplayName', sprintf('%s MC', st.name));

    plot(tt, mc{i}.bound_time, ...
        '--', ...
        'Color', st.color, ...
        'LineWidth', 1.6, ...
        'DisplayName', sprintf('%s BCRLB', st.name));
end

xlabel('Time / s');
ylabel('Position RMSE / m');
title(sprintf('Monte Carlo RMSE vs dynamic BCRLB, \\sigma_{GNSS}=%.1f m', gnssEval));
subtitle(sprintf('N_{MC} = %d', cfg.mc.Nrun));
apply_axis_style(gca);
legend('Location','northwest');

% ==============================================================
% Scheme3 b: final metrics
% ==============================================================
new_paper_figure('Scheme3_final_metric', [130 130 800 560]);
hold on;

FinalMC = zeros(nC,1);
FinalBCRLB = zeros(nC,1);
FinalMC_CI_L = nan(nC,1);
FinalMC_CI_U = nan(nC,1);
ConsistencyRatio = zeros(nC,1);

for i = 1:nC
    FinalMC(i) = mc{i}.final_rmse;
    FinalBCRLB(i) = mc{i}.bound_rmse;
    if isfield(mc{i}, 'final_rmse_ci95')
        FinalMC_CI_L(i) = mc{i}.final_rmse_ci95(1);
        FinalMC_CI_U(i) = mc{i}.final_rmse_ci95(2);
    end
    ConsistencyRatio(i) = FinalMC(i) / max(FinalBCRLB(i), eps);
end

catLabels = categorical(cellstr(labels));
catLabels = reordercats(catLabels, cellstr(labels));

Y = [FinalMC, FinalBCRLB];
bar(catLabels, Y, 0.65);

if all(isfinite(FinalMC_CI_L))
    errLow = FinalMC - FinalMC_CI_L;
    errHigh = FinalMC_CI_U - FinalMC;
    errorbar((1:nC)-0.15, FinalMC, errLow, errHigh, ...
        'k.', 'LineWidth', 1.1, 'HandleVisibility','off');
end

ylabel('Metric / m');
title('Final RMSE and BCRLB by strategy');
legend({'MC final RMSE','final BCRLB'}, 'Location','northwest');
apply_axis_style(gca);

for i = 1:nC
    text(i-0.15, FinalMC(i), sprintf('%.2f', FinalMC(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',10);

    text(i+0.15, FinalBCRLB(i), sprintf('%.2f', FinalBCRLB(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',10);
end

text(0.02, 0.95, compose("MC/BCRLB ratio: %s", ...
    strjoin(compose("%s %.2f", labels, ConsistencyRatio), ", ")), ...
    'Units','normalized', ...
    'VerticalAlignment','top', ...
    'BackgroundColor','w', ...
    'Margin',5);

% ==============================================================
% Scheme3 c: all-family final error ellipses
% ==============================================================
new_paper_figure('Scheme3_all_family_error_ellipses', [150 150 860 720]);
hold on;

for i = 1:nC
    fam = char(cand{i}.family);
    st = family_style(fam);
    isRobust = i == robustIdx;

    scatter(mc{i}.scatter(:,1), mc{i}.scatter(:,2), 22, ...
        'filled', ...
        'MarkerFaceColor', st.color, ...
        'MarkerFaceAlpha', 0.16 + 0.12 * isRobust, ...
        'MarkerEdgeAlpha', 0.10, ...
        'DisplayName', sprintf('%s MC', st.name));

    plot_error_ellipse([0;0], mc{i}.Pxy_bound, ...
        'Color', st.color, ...
        'LineWidth', 1.8 + 1.2 * isRobust, ...
        'DisplayName', sprintf('%s BCRLB ellipse%s', st.name, local_robust_suffix(isRobust)));
end

local_equalize_error_axes(gca);
scatter(0,0,100,'p', ...
    'MarkerFaceColor',[0.85 0.05 0.05], ...
    'MarkerEdgeColor','k', ...
    'DisplayName','zero error');

xlabel('x error / m');
ylabel('y error / m');
title(sprintf('Final error clouds and 95%% BCRLB ellipses, robust = %s', char(robust.family)));
axis equal;
apply_axis_style(gca);
legend('Location','bestoutside');

% ==============================================================
% Scheme3 d: robust scatter
% ==============================================================
new_paper_figure('Scheme3_robust_scatter', [160 160 720 620]);
hold on;

scatter(mc{robustIdx}.scatter(:,1), mc{robustIdx}.scatter(:,2), 22, ...
    'filled', ...
    'MarkerFaceColor', [0.10 0.58 0.28], ...
    'MarkerFaceAlpha', 0.35, ...
    'MarkerEdgeAlpha', 0.15);

plot_error_ellipse([0;0], mc{robustIdx}.Pxy_bound, ...
    'Color', [0.10 0.58 0.28], ...
    'LineWidth', 2.5);

scatter(0,0,100,'p', ...
    'MarkerFaceColor',[0.85 0.05 0.05], ...
    'MarkerEdgeColor','k');

xlabel('x error / m');
ylabel('y error / m');
title(sprintf('Final error cloud: robust strategy (%s)', labels(robustIdx)));
axis equal;
apply_axis_style(gca);

% ==============================================================
% Scheme3 e: comparison scatter
% ==============================================================
score = zeros(nC,1);
for i = 1:nC
    score(i) = cand{i}.score;
end

[~, order] = sort(score, 'ascend');

secondIdx = order(1);
if secondIdx == robustIdx && numel(order) >= 2
    secondIdx = order(2);
end

new_paper_figure('Scheme3_comparison_scatter', [190 190 720 620]);
hold on;

scatter(mc{secondIdx}.scatter(:,1), mc{secondIdx}.scatter(:,2), 22, ...
    'filled', ...
    'MarkerFaceColor', [0.86 0.46 0.08], ...
    'MarkerFaceAlpha', 0.35, ...
    'MarkerEdgeAlpha', 0.15);

plot_error_ellipse([0;0], mc{secondIdx}.Pxy_bound, ...
    'Color', [0.86 0.46 0.08], ...
    'LineWidth', 2.5);

scatter(0,0,100,'p', ...
    'MarkerFaceColor',[0.85 0.05 0.05], ...
    'MarkerEdgeColor','k');

xlabel('x error / m');
ylabel('y error / m');
title(sprintf('Final error cloud: comparison strategy (%s)', labels(secondIdx)));
axis equal;
apply_axis_style(gca);

end

function s = local_robust_suffix(isRobust)
if isRobust
    s = ' (robust)';
else
    s = '';
end
end

function local_equalize_error_axes(ax)
xl = xlim(ax);
yl = ylim(ax);
r = max(abs([xl(:); yl(:); 1]));
xlim(ax, [-r r]);
ylim(ax, [-r r]);
end
