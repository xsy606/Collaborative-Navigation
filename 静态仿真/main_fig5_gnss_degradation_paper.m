function OUT = main_fig5_gnss_degradation_paper()
%MAIN_FIG5_GNSS_DEGRADATION_PAPER
% Paper-style Figure 5: separate windows for RMSE and sensitivity.

close all;
paper_style();
cfg = default_config();

families = {'line','wedge','polygon'};
N = cfg.example.N;
s = cfg.example.s;
beta_deg = cfg.example.beta_deg;

gnssFine = linspace(min(cfg.grid.gnss), max(cfg.grid.gnss), 41);

% Common feasible rate.
fphysMin = inf;
for i = 1:numel(families)
    A = build_formation(families{i}, N, s, ...
        struct('beta_deg', beta_deg, 'rot_deg', 0));
    fphysMin = min(fphysMin, acoustic_physical_limit(A, cfg));
end

fCommon = min(cfg.example.f, 0.95 * fphysMin);

OUT = struct();
OUT.gnssFine = gnssFine;
OUT.fCommon = fCommon;

% ==============================================================
% Figure 5a: RMSE vs GNSS
% ==============================================================
new_paper_figure('Fig5_GNSS_RMSE', [100 100 860 620]);
hold on;
yAxisMax = cfg.requirement.rmse_xy;
best = struct('sigma', gnssFine(1), 'rmse', inf, 'label', "", 'color', [0.1 0.1 0.1]);

for i = 1:numel(families)
    fam = families{i};
    st = family_style(fam);

    y = nan(size(gnssFine));

    for k = 1:numel(gnssFine)
        rec = evaluate_design(fam, N, s, beta_deg, fCommon, gnssFine(k), cfg, ...
            'StoreSeries', false);
        y(k) = rec.rmse_xy;
    end

    plot(gnssFine, y, ...
        '-', ...
        'Color', st.color, ...
        'Marker', st.marker, ...
        'MarkerIndices', 1:5:numel(gnssFine), ...
        'MarkerFaceColor', st.color, ...
        'MarkerSize', 5.5, ...
        'LineWidth', 2.3, ...
        'DisplayName', st.name);

    [ymin, idxMin] = min(y);
    yAxisMax = max(yAxisMax, max(y));
    if ymin < best.rmse
        best.sigma = gnssFine(idxMin);
        best.rmse = ymin;
        best.label = sprintf('%s best', st.name);
        best.color = st.color;
    end

    OUT.(sprintf('%s_rmse', fam)) = y;
end

xlabel('\sigma_{GNSS} / m');
ylabel('Horizontal RMSE lower bound / m');
title('GNSS degradation effect on localization lower bound');
subtitle(sprintf('Common f = %.2f Hz, N = %d, s = %.0f m', fCommon, N, s));
ylim([0, yAxisMax*1.15]);
plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE');
annotate_best_point(gca, best.sigma, best.rmse, best.label, best.color);
apply_axis_style(gca);
legend('Location','northwest');

% ==============================================================
% Figure 5b: sensitivity
% ==============================================================
new_paper_figure('Fig5_GNSS_sensitivity', [130 130 860 620]);
hold on;

for i = 1:numel(families)
    fam = families{i};
    st = family_style(fam);

    y = OUT.(sprintf('%s_rmse', fam));
    sens = gradient(y, gnssFine);

    plot(gnssFine, sens, ...
        '-', ...
        'Color', st.color, ...
        'Marker', st.marker, ...
        'MarkerIndices', 1:5:numel(gnssFine), ...
        'MarkerFaceColor', st.color, ...
        'MarkerSize', 5.5, ...
        'LineWidth', 2.3, ...
        'DisplayName', st.name);

    OUT.(sprintf('%s_sensitivity', fam)) = sens;
end

xlabel('\sigma_{GNSS} / m');
ylabel('d(RMSE_{xy}) / d\sigma_{GNSS}');
title('Sensitivity to GNSS degradation');
subtitle('Numerical derivative based on fine GNSS grid');
apply_axis_style(gca);
legend('Location','northwest');

end
