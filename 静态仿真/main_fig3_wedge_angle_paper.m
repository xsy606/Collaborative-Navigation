function OUT = main_fig3_wedge_angle_paper()
%MAIN_FIG3_WEDGE_ANGLE_PAPER
% Paper-style Figure 3: separate windows and finer beta grid.

close all;
paper_style();
cfg = default_config('paper');

N = cfg.example.N;
sList = [100, 200, 300];
sigmaList = [cfg.meas.rtk_sigma, cfg.meas.gnss_sigma_default];
sigmaName = {'RTK-like','GNSS-degraded'};

betaFine = 20:5:180;

% Common feasible update rate.
fphysMin = inf;
for s = sList
    for beta = betaFine
        A = build_formation('wedge', N, s, struct('beta_deg', beta, 'rot_deg', 0));
        fphysMin = min(fphysMin, acoustic_physical_limit(A, cfg));
    end
end

fCommon = min(cfg.example.f, 0.95 * fphysMin);

OUT = struct();
OUT.betaFine = betaFine;
OUT.fCommon = fCommon;

C = lines(numel(sList));

for row = 1:2
    new_paper_figure(sprintf('Fig3_%s_wedge_angle', sigmaName{row}), [110 110 860 620]);
    hold on;
    yAxisMax = cfg.requirement.rmse_xy;
    best = struct('beta', betaFine(1), 'rmse', inf, 'label', "", 'color', [0.1 0.1 0.1]);

    for is = 1:numel(sList)
        s = sList(is);
        y = nan(size(betaFine));

        for k = 1:numel(betaFine)
            beta = betaFine(k);
            rec = evaluate_design('wedge', N, s, beta, fCommon, sigmaList(row), cfg, ...
                'StoreSeries', false);
            y(k) = rec.rmse_xy;
        end

        plot(betaFine, y, ...
            '-', ...
            'Color', C(is,:), ...
            'Marker', 'o', ...
            'MarkerIndices', 1:4:numel(betaFine), ...
            'MarkerFaceColor', C(is,:), ...
            'MarkerSize', 5.5, ...
            'LineWidth', 2.2, ...
            'DisplayName', sprintf('s = %d m', s));

        [ymin, idxMin] = min(y);
        yAxisMax = max(yAxisMax, max(y));
        if ymin < best.rmse
            best.beta = betaFine(idxMin);
            best.rmse = ymin;
            best.label = sprintf('best, s=%d m, \\beta=%.0f^\\circ', s, best.beta);
            best.color = C(is,:);
        end

        OUT.(sprintf('s%d_sigma%d', s, row)) = y;
        OUT.(sprintf('s%d_beta_opt_sigma%d', s, row)) = betaFine(idxMin);
    end

    xlabel('Wedge opening angle \beta / deg');
    ylabel('Horizontal RMSE lower bound / m');
    title(sprintf('Wedge opening-angle sensitivity (%s)', sigmaName{row}));
    subtitle(sprintf('Common f = %.2f Hz, N = %d', fCommon, N));

    xline(120, ':', '120^\circ reference', ...
        'Color',[0.25 0.25 0.25], ...
        'LineWidth',1.2, ...
        'LabelVerticalAlignment','bottom');
    ylim([0, yAxisMax*1.15]);
    plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE');
    annotate_best_point(gca, best.beta, best.rmse, best.label, best.color);

    apply_axis_style(gca);
    legend('Location','northeast');
end

end
