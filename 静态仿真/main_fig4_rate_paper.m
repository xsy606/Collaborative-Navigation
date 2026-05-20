function OUT = main_fig4_rate_paper()
%MAIN_FIG4_RATE_PAPER
% Paper-style Figure 4: separate windows, clean legend, independent fmax chart.

close all;
paper_style();
cfg = default_config();

families = {'line','wedge','polygon'};
N = cfg.example.N;
beta_deg = cfg.example.beta_deg;
footprintRef = cfg.example.footprint;

sigmaList = [cfg.meas.rtk_sigma, cfg.meas.gnss_sigma_default];
sigmaName = {'RTK-like','GNSS-degraded'};

fFine = 0.1:0.05:2.0;

OUT = struct();

fphysVec = zeros(numel(families),1);

for row = 1:2
    new_paper_figure(sprintf('Fig4_%s_update_rate', sigmaName{row}), [120 120 880 620]);
    hold on;
    yAxisMax = cfg.requirement.rmse_xy;

    for i = 1:numel(families)
        fam = families{i};
        st = family_style(fam);
        anchors = build_formation_with_footprint(fam, N, footprintRef, ...
            struct('beta_deg', beta_deg, 'rot_deg', 0));

        recRef = evaluate_anchor_geometry(fam, anchors, beta_deg, ...
            min(fFine), sigmaList(row), cfg, ...
            'StoreSeries', false);
        fphys = recRef.f_phys_max;

        if row == 1
            fphysVec(i) = fphys;
        end

        yFeas = nan(size(fFine));
        yCap = nan(size(fFine));

        for k = 1:numel(fFine)
            fReq = fFine(k);

            if fReq <= fphys
                rec = evaluate_anchor_geometry(fam, anchors, beta_deg, ...
                    fReq, sigmaList(row), cfg, ...
                    'StoreSeries', false);
                yFeas(k) = rec.rmse_xy;
            end

            fEff = min(fReq, fphys);
            recCap = evaluate_anchor_geometry(fam, anchors, beta_deg, ...
                fEff, sigmaList(row), cfg, ...
                'StoreSeries', false);
            yCap(k) = recCap.rmse_xy;
        end

        plot(fFine, yCap, '--', ...
            'Color', st.color, ...
            'LineWidth', 1.6, ...
            'DisplayName', sprintf('%s capped', st.name));

        plot(fFine, yFeas, '-', ...
            'Color', st.color, ...
            'Marker', st.marker, ...
            'MarkerIndices', 1:6:numel(fFine), ...
            'MarkerFaceColor', st.color, ...
            'MarkerSize', 5.5, ...
            'LineWidth', 2.3, ...
            'DisplayName', sprintf('%s feasible', st.name));

        % Light feasible region background close to each fmax.
        xline(fphys, ':', ...
            'Color', st.color, ...
            'LineWidth', 1.2, ...
            'HandleVisibility','off');

        OUT.(sprintf('%s_fphys', fam)) = fphys;
        OUT.(sprintf('%s_feas_sigma%d', fam, row)) = yFeas;
        OUT.(sprintf('%s_cap_sigma%d', fam, row)) = yCap;
        finiteCap = yCap(isfinite(yCap));
        if ~isempty(finiteCap)
            yAxisMax = max(yAxisMax, max(finiteCap));
        end
    end

    xlabel('Requested acoustic update rate / Hz');
    ylabel('Horizontal RMSE lower bound / m');
    title(sprintf('Acoustic update-rate sensitivity (%s)', sigmaName{row}));
    subtitle(sprintf('Footprint-normalized comparison, footprint = %.0f m', footprintRef));
    ylim([0, yAxisMax*1.15]);
    plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE');

    apply_axis_style(gca);
    legend('Location','northeast');

end

% Independent physical limit chart.
new_paper_figure('Fig4_acoustic_physical_limits', [160 160 720 520]);
hold on;

Y = fphysVec(:);
b = bar(Y, 0.55);
b.FaceColor = 'flat';

for i = 1:numel(families)
    st = family_style(families{i});
    b.CData(i,:) = st.color;
end

set(gca, 'XTick', 1:numel(families), 'XTickLabel', {'Line','Wedge','Polygon'});
ylabel('Physical upper update rate / Hz');
title(sprintf('Acoustic physical update-rate upper bounds, footprint = %.0f m', footprintRef));

for i = 1:numel(Y)
    text(i, Y(i), sprintf(' %.3f Hz', Y(i)), ...
        'VerticalAlignment','bottom', ...
        'HorizontalAlignment','center', ...
        'FontSize',11);
end

apply_axis_style(gca);

OUT.fphysTable = table(string(families(:)), fphysVec, ...
    'VariableNames', {'family','f_phys_max'});

assignin('base', 'fig4_fphys_table', OUT.fphysTable);

end
