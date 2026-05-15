function OUT = main_fig5_gnss_degradation()
% Figure 5 revised: GNSS degradation with fine grid and smoother sensitivity.

close all;
cfg = default_config();

families = {'line','wedge','polygon'};
N = cfg.example.N;
s = cfg.example.s;
beta_deg = cfg.example.beta_deg;

gnssFine = linspace(min(cfg.grid.gnss), max(cfg.grid.gnss), 31);

% Common feasible rate across example geometries.
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

figure('Color','w','Position',[100 100 1250 530]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

nexttile; hold on; grid on; box on;

for i = 1:numel(families)
    fam = families{i};
    y = nan(size(gnssFine));

    for k = 1:numel(gnssFine)
        rec = evaluate_design(fam, N, s, beta_deg, fCommon, gnssFine(k), cfg, ...
            'StoreSeries', false);
        y(k) = rec.rmse_xy;
    end

    plot(gnssFine, y, '-o', 'LineWidth', 1.8, ...
        'MarkerSize', 3.0, ...
        'DisplayName', fam);

    OUT.(sprintf('%s_rmse', fam)) = y;
end

xlabel('\sigma_{GNSS} / m');
ylabel('Horizontal RMSE lower bound / m');
title(sprintf('GNSS degradation | common f = %.2f Hz', fCommon));
legend('Location','northwest');

nexttile; hold on; grid on; box on;

for i = 1:numel(families)
    fam = families{i};
    y = OUT.(sprintf('%s_rmse', fam));

    sens = gradient(y, gnssFine);

    plot(gnssFine, sens, 'LineWidth', 2, 'DisplayName', fam);
    OUT.(sprintf('%s_sensitivity', fam)) = sens;
end

xlabel('\sigma_{GNSS} / m');
ylabel('d(RMSE_{xy}) / d\sigma_{GNSS}');
title('Sensitivity to GNSS degradation');
legend('Location','northwest');

sgtitle('Figure 5 revised  GNSS degradation and sensitivity with fine grid');

end
