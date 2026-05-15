function OUT = main_fig2_spacing()
% Figure 2: Adjacent spacing sweep.
% Use a common feasible acoustic rate to isolate geometry effect.

close all;
cfg = default_config();

families = {'line','wedge','polygon'};
N = cfg.example.N;
beta_deg = cfg.example.beta_deg;
sigmaList = [cfg.meas.rtk_sigma, cfg.meas.gnss_sigma_default];
sigmaName = {'RTK-like','GNSS-degraded'};

% Common feasible rate across all tested geometries
fphysMin = inf;
for i = 1:numel(families)
    for s = cfg.grid.s
        A = build_formation(families{i}, N, s, ...
            struct('beta_deg', beta_deg, 'rot_deg', 180/N));
        fphysMin = min(fphysMin, acoustic_physical_limit(A, cfg));
    end
end

fCommon = min(cfg.example.f, 0.95 * fphysMin);

OUT = struct();
OUT.fCommon = fCommon;

figure('Color','w','Position',[100 100 1200 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for row = 1:2
    nexttile; hold on; grid on; box on;

    for i = 1:numel(families)
        fam = families{i};
        y = nan(size(cfg.grid.s));

        for k = 1:numel(cfg.grid.s)
            s = cfg.grid.s(k);
            rec = evaluate_design(fam, N, s, beta_deg, fCommon, sigmaList(row), cfg, ...
                'StoreSeries', false);
            y(k) = rec.rmse_xy;
        end

        plot(cfg.grid.s, y, 'LineWidth', 2, 'DisplayName', fam);
        OUT.(sprintf('%s_%d', fam, row)) = y;
    end

    xlabel('Adjacent spacing s / m');
    ylabel('Horizontal RMSE lower bound / m');
    title(sprintf('%s | common f = %.2f Hz', sigmaName{row}, fCommon));
    legend('Location','best');
end

sgtitle('Figure 2  Spacing sensitivity under common feasible update rate');

end
