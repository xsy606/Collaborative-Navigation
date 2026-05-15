function S = main_fig1_ellipse_paper()
%MAIN_FIG1_ELLIPSE_PAPER
% Paper-style Figure 1:
%   separate windows for formation ellipse and metric comparison.

close all;
paper_style();
pal = paper_palette();
cfg = default_config('paper');

families = {'line','wedge','polygon'};
sigmaList = [cfg.meas.rtk_sigma, cfg.meas.gnss_sigma_default];
sigmaName = {'RTK-like','GNSS-degraded'};

S = struct();

% Common feasible update rate.
fphysAll = zeros(1, numel(families));

for i = 1:numel(families)
    fam = families{i};
    A = build_formation(fam, cfg.example.N, cfg.example.s, ...
        struct('beta_deg', cfg.example.beta_deg, 'rot_deg', 0));
    fphysAll(i) = acoustic_physical_limit(A, cfg);
end

fCommon = min(cfg.example.f, 0.95 * min(fphysAll));

for row = 1:2
    sigma_gnss = sigmaList(row);

    % ==============================================================
    % Figure 1a / 1b: formation + error ellipse
    % ==============================================================
    figName = sprintf('Fig1_%s_formation_ellipse', sigmaName{row});
    new_paper_figure(figName, [80 80 880 680]);
    hold on;

    for i = 1:numel(families)
        fam = families{i};
        st = family_style(fam);

        rec = evaluate_design(fam, cfg.example.N, cfg.example.s, ...
            cfg.example.beta_deg, fCommon, sigma_gnss, cfg, ...
            'StoreSeries', false);

        S.(sprintf('%s_%d', fam, row)) = rec;

        % Formation convex hull or line envelope
        if size(rec.anchors,1) >= 3 && rank(rec.anchors - mean(rec.anchors,1)) >= 2
            try
                k = convhull(rec.anchors(:,1), rec.anchors(:,2));
                patch(rec.anchors(k,1), rec.anchors(k,2), st.color, ...
                    'FaceAlpha', 0.06, ...
                    'EdgeColor', st.color, ...
                    'LineWidth', 1.4, ...
                    'HandleVisibility','off');
            catch
            end
        else
            plot(rec.anchors(:,1), rec.anchors(:,2), '-', ...
                'Color', st.color, ...
                'LineWidth', 1.2, ...
                'HandleVisibility','off');
        end

        % USV anchors
        scatter(rec.anchors(:,1), rec.anchors(:,2), 70, ...
            st.marker, ...
            'MarkerFaceColor', st.color, ...
            'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.8, ...
            'DisplayName', sprintf('%s USVs', st.name));

        % LOS lines
        for j = 1:size(rec.anchors,1)
            plot([rec.anchors(j,1), cfg.target.nominal_state(1)], ...
                 [rec.anchors(j,2), cfg.target.nominal_state(2)], ...
                 ':', ...
                 'Color', [st.color 0.35], ...
                 'LineWidth', 0.9, ...
                 'HandleVisibility','off');
        end

        % Error ellipse
        plot_error_ellipse(cfg.target.nominal_state(1:2), rec.Pxy, ...
            'Color', st.color, ...
            'LineWidth', 2.4, ...
            'DisplayName', sprintf('%s 95%% ellipse', st.name));
    end

    % AUV
    scatter(cfg.target.nominal_state(1), cfg.target.nominal_state(2), ...
        150, 'p', ...
        'MarkerFaceColor', [0.85 0.05 0.05], ...
        'MarkerEdgeColor', 'k', ...
        'LineWidth', 0.8, ...
        'DisplayName', 'AUV');

    xlabel('x / m');
    ylabel('y / m');
    title(sprintf('Formation geometry and 95%% error ellipse (%s)', sigmaName{row}));
    axis equal;
    apply_axis_style(gca);
    legend('Location','eastoutside');

    txt = sprintf('\\sigma_{GNSS}=%.2f m, f=%.2f Hz', sigma_gnss, fCommon);
    text(0.02, 0.97, txt, ...
        'Units','normalized', ...
        'VerticalAlignment','top', ...
        'BackgroundColor','w', ...
        'EdgeColor',[0.75 0.75 0.75], ...
        'Margin',6);

    % ==============================================================
    % Figure 1c / 1d: metric bar charts
    % ==============================================================
    new_paper_figure(sprintf('Fig1_%s_metric_bars', sigmaName{row}), [120 120 900 600]);

    metricName = {'RMSE', 'Major95', 'Area95', 'Cond.'};
    Y = zeros(numel(families), 4);

    for i = 1:numel(families)
        fam = families{i};
        rec = S.(sprintf('%s_%d', fam, row));

        Y(i,:) = [rec.rmse_xy, rec.major95, rec.area95, rec.condnum];
    end

    % Normalize for visual comparison.
    Yn = Y ./ max(Y, [], 1);

    b = bar(Yn, 'grouped');
    barColors = [pal.navy; pal.green; pal.orange; pal.purple];
    for k = 1:numel(b)
        b(k).LineWidth = 0.8;
        b(k).FaceColor = barColors(k,:);
        b(k).FaceAlpha = 0.86;
    end

    set(gca, 'XTickLabel', {'Line','Wedge','Polygon'});
    ylabel('Normalized value');
    title(sprintf('Normalized localization metrics (%s)', sigmaName{row}));
    legend(metricName, 'Location','northoutside', 'Orientation','horizontal');
    apply_axis_style(gca);

    % Add actual values as text.
    xt = 1:numel(families);
    for i = 1:numel(families)
        text(xt(i), 1.08, ...
            sprintf('RMSE %.2f m', Y(i,1)), ...
            'HorizontalAlignment','center', ...
            'FontSize',10);
    end

    ylim([0, 1.22]);
end

end
