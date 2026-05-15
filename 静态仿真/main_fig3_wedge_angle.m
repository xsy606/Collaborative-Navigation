function OUT = main_fig3_wedge_angle()
% Figure 3 revised: Wedge opening-angle sweep with fine beta grid.

close all;
cfg = default_config('paper');

N = cfg.example.N;
sList = [100, 200, 300];
sigmaList = [cfg.meas.rtk_sigma, cfg.meas.gnss_sigma_default];
sigmaName = {'RTK-like','GNSS-degraded'};

betaFine = 20:5:180;

% Common feasible rate across all wedge geometries.
fphysMin = inf;
for s = sList
    for beta = betaFine
        A = build_formation('wedge', N, s, struct('beta_deg', beta));
        fphysMin = min(fphysMin, acoustic_physical_limit(A, cfg));
    end
end

fCommon = min(cfg.example.f, 0.95 * fphysMin);

OUT = struct();
OUT.betaFine = betaFine;
OUT.fCommon = fCommon;

figure('Color','w','Position',[100 100 1250 540]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for row = 1:2
    nexttile; hold on; grid on; box on;

    for is = 1:numel(sList)
        s = sList(is);
        y = nan(size(betaFine));

        for k = 1:numel(betaFine)
            beta = betaFine(k);
            rec = evaluate_design('wedge', N, s, beta, fCommon, sigmaList(row), cfg, ...
                'StoreSeries', false);
            y(k) = rec.rmse_xy;
        end

        plot(betaFine, y, '-o', 'LineWidth', 1.8, ...
            'MarkerSize', 3.5, ...
            'DisplayName', sprintf('s = %d m', s));

        [ymin, idxMin] = min(y);
        plot(betaFine(idxMin), ymin, 'p', 'MarkerSize', 11, ...
            'HandleVisibility','off');

        OUT.(sprintf('s%d_sigma%d', s, row)) = y;
        OUT.(sprintf('s%d_beta_opt_sigma%d', s, row)) = betaFine(idxMin);
    end

    xlabel('Wedge opening angle \beta / deg');
    ylabel('Horizontal RMSE lower bound / m');
    title(sprintf('%s | common f = %.2f Hz', sigmaName{row}, fCommon));
    legend('Location','best');
end

sgtitle('Figure 3 revised  Wedge opening-angle sensitivity with fine grid');

end
