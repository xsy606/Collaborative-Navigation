function OUT = main_scheme2_robust_paper()
%MAIN_SCHEME2_ROBUST_PAPER
% Paper-style Scheme 2: separate windows and stacked cost chart.

close all;
paper_style();
cfg = default_config();
pal = paper_palette();

gnss = cfg.grid.gnss;
robust = find_global_robust_strategy(cfg, gnss);
cand = robust.allFamilies;

OUT.robust = robust;
OUT.candidates = cand;

nC = numel(cand);

Family = strings(nC,1);
CostShip = zeros(nC,1);
CostFoot = zeros(nC,1);
CostRate = zeros(nC,1);
CostFootExcess = zeros(nC,1);
CostTotal = zeros(nC,1);

for i = 1:nC
    Family(i) = string(cand{i}.family);
    [~, bd] = family_cost(cand{i}.family, cand{i}.anchors, cand{i}.N, cand{i}.f_ac, cfg);
    CostShip(i) = bd.c_ship;
    CostFoot(i) = bd.c_foot;
    CostRate(i) = bd.c_rate;
    CostFootExcess(i) = bd.c_foot_excess;
    CostTotal(i) = bd.total;
end

% ==============================================================
% Scheme2 a: RMSE curves
% ==============================================================
new_paper_figure('Scheme2_family_best_RMSE', [100 100 860 620]);
hold on;

for i = 1:nC
    fam = char(cand{i}.family);
    st = family_style(fam);

    plot(gnss, cand{i}.rmseVec, ...
        '-o', ...
        'Color', st.color, ...
        'MarkerFaceColor', st.color, ...
        'MarkerSize', 6, ...
        'LineWidth', 2.3, ...
        'DisplayName', sprintf('%s-best', st.name));
end

xlabel('\sigma_{GNSS} / m');
ylabel('Horizontal RMSE lower bound / m');
title('Family-best fixed strategies under GNSS degradation');
ylim([0, max(cellfun(@(x) max(x.rmseVec), cand))*1.12]);
plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE', 'Color', pal.target);
apply_axis_style(gca);
legend('Location','northwest');

% ==============================================================
% Scheme2 b: exceedance
% ==============================================================
new_paper_figure('Scheme2_exceedance', [130 130 860 620]);
hold on;

for i = 1:nC
    fam = char(cand{i}.family);
    st = family_style(fam);

    y = cand{i}.rmseVec - cfg.requirement.rmse_xy;

    area(gnss, max(y,0), ...
        'FaceColor', st.color, ...
        'FaceAlpha', 0.10, ...
        'EdgeColor','none', ...
        'HandleVisibility','off');

    plot(gnss, y, ...
        '-o', ...
        'Color', st.color, ...
        'MarkerFaceColor', st.color, ...
        'MarkerSize', 6, ...
        'LineWidth', 2.3, ...
        'DisplayName', sprintf('%s-best', st.name));
end

xlabel('\sigma_{GNSS} / m');
ylabel('RMSE exceedance over target / m');
title('Exceedance over target accuracy');
yline(0, '--', 'Target boundary', ...
    'Color',[0.35 0.35 0.35], 'LineWidth',1.4);
apply_axis_style(gca);
legend('Location','northwest');

% ==============================================================
% Scheme2 c: cost breakdown
% ==============================================================
new_paper_figure('Scheme2_cost_breakdown', [160 160 780 560]);
hold on;

Y = [CostShip, CostFoot, CostRate, CostFootExcess];
b = bar(Y, 'stacked', 'BarWidth', 0.58);

b(1).FaceColor = [0.30 0.47 0.78];
b(2).FaceColor = [0.58 0.72 0.40];
b(3).FaceColor = [0.86 0.50 0.22];
b(4).FaceColor = [0.62 0.45 0.72];

set(gca, 'XTick', 1:nC, 'XTickLabel', cellstr(Family));
ylabel('Cost proxy');
title('Cost breakdown of family-best strategies');
apply_axis_style(gca);
ylim([0, max(CostTotal)*1.18]);

for i = 1:nC
    text(i, CostTotal(i), sprintf(' %.2f', CostTotal(i)), ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','bottom', ...
        'FontSize',11);
end

robustIdx = find(strcmpi(Family, string(robust.family)), 1);
if ~isempty(robustIdx)
    plot(robustIdx, CostTotal(robustIdx)*1.06, 'p', ...
        'MarkerSize',13, ...
        'MarkerFaceColor', pal.red, ...
        'MarkerEdgeColor','w', ...
        'LineWidth',1.0, ...
        'DisplayName','robust selected');
end

legend({'ship-count','footprint','update-rate','excess-footprint','robust selected'}, ...
    'Location','northwest');

% ==============================================================
% Scheme2 d: strategy table as text
% ==============================================================
new_paper_figure('Scheme2_strategy_table', [190 190 960 520]);
axis off;

txt = strings(nC + 5, 1);
lineIdx = 0;
lineIdx = lineIdx + 1;
txt(lineIdx) = 'Scheme 2 family-best strategy summary';
lineIdx = lineIdx + 1;
txt(lineIdx) = ' ';
lineIdx = lineIdx + 1;
txt(lineIdx) = sprintf('%-10s %-4s %-8s %-8s %-8s %-10s %-8s %-8s', ...
    'Family','N','s/m','beta/deg','f/Hz','fmax/Hz','cost','score');

for i = 1:nC
    c = cand{i};
    lineIdx = lineIdx + 1;
    txt(lineIdx) = sprintf('%-10s %-4d %-8.0f %-8.0f %-8.2f %-10.3f %-8.2f %-8.3f', ...
        char(c.family), c.N, c.s, c.beta_deg, c.f_ac, c.f_phys_max, c.cost, c.score);
end

lineIdx = lineIdx + 1;
txt(lineIdx) = ' ';
lineIdx = lineIdx + 1;
txt(lineIdx) = sprintf('Selected robust strategy: %s, N=%d, s=%.0f m, beta=%.0f deg, f=%.2f Hz', ...
    char(robust.family), robust.N, robust.s, robust.beta_deg, robust.f_ac);
txt = txt(1:lineIdx);

text(0.03, 0.95, txt, ...
    'FontName','Consolas', ...
    'FontSize', 11, ...
    'VerticalAlignment','top');

OUT.summaryText = txt;

end
