function OUT = main_fig2_spacing_paper()
%MAIN_FIG2_SPACING_PAPER
% Paper-style Figure 2: separate windows for RTK and GNSS spacing sweep.

close all;
paper_style();
cfg = default_config('paper');

families = {'line','wedge','polygon'};
N = cfg.example.N;
beta_deg = cfg.example.beta_deg;

sigmaList = [cfg.meas.rtk_sigma, cfg.meas.gnss_sigma_default];
sigmaName = {'RTK-like','GNSS-degraded'};

sFine = min(cfg.grid.s):25:max(cfg.grid.s);

% Common feasible update rate.
fphysMin = inf;
for i = 1:numel(families)
    for s = sFine
        A = build_formation(families{i}, N, s, ...
            struct('beta_deg', beta_deg, 'rot_deg', 0));
        fphysMin = min(fphysMin, acoustic_physical_limit(A, cfg));
    end
end

fCommon = min(cfg.example.f, 0.95 * fphysMin);

OUT = struct();
OUT.sFine = sFine;
OUT.fCommon = fCommon;

for row = 1:2
    new_paper_figure(sprintf('Fig2_%s_spacing_sensitivity', sigmaName{row}), [90 90 860 620]);
    hold on;
    yAxisMax = cfg.requirement.rmse_xy;
    best = struct('s', sFine(1), 'rmse', inf, 'label', "", 'color', [0.1 0.1 0.1]);

    for i = 1:numel(families)
        fam = families{i};
        st = family_style(fam);

        y = nan(size(sFine));

        for k = 1:numel(sFine)
            s = sFine(k);
            rec = evaluate_design(fam, N, s, beta_deg, fCommon, sigmaList(row), cfg, ...
                'StoreSeries', false);
            y(k) = rec.rmse_xy;
        end

        plot(sFine, y, ...
            '-', ...
            'Color', st.color, ...
            'Marker', st.marker, ...
            'MarkerIndices', 1:3:numel(sFine), ...
            'MarkerSize', 6, ...
            'MarkerFaceColor', st.color, ...
            'LineWidth', 2.2, ...
            'DisplayName', st.name);

        [ymin, idxMin] = min(y);
        yAxisMax = max(yAxisMax, max(y));
        if ymin < best.rmse
            best.s = sFine(idxMin);
            best.rmse = ymin;
            best.label = sprintf('%s best, s=%.0f m', st.name, best.s);
            best.color = st.color;
        end

        OUT.(sprintf('%s_%d', fam, row)) = y;
    end

    xlabel('Adjacent spacing s / m');
    ylabel('Horizontal RMSE lower bound / m');
    title(sprintf('Spacing sensitivity under common feasible update rate (%s)', sigmaName{row}));
    subtitle(sprintf('Common f = %.2f Hz, N = %d', fCommon, N));
    ylim([0, yAxisMax*1.15]);
    plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE');
    annotate_best_point(gca, best.s, best.rmse, best.label, best.color);

    apply_axis_style(gca);
    legend('Location','northeast');

end

end
