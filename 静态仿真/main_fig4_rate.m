function OUT = main_fig4_rate()
% Figure 4 revised: acoustic update rate with clean legend and fmax table.

close all;
cfg = default_config();

families = {'line','wedge','polygon'};
N = cfg.example.N;
s = cfg.example.s;
beta_deg = cfg.example.beta_deg;
sigmaList = [cfg.meas.rtk_sigma, cfg.meas.gnss_sigma_default];
sigmaName = {'RTK-like','GNSS-degraded'};

fFine = 0.1:0.05:2.0;
C = lines(numel(families));

OUT = struct();

figure('Color','w','Position',[80 80 1450 560]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

fmaxTable = table();

for row = 1:2
    nexttile; hold on; grid on; box on;

    for i = 1:numel(families)
        fam = families{i};

        recRef = evaluate_design(fam, N, s, beta_deg, min(fFine), sigmaList(row), cfg, ...
            'StoreSeries', false);
        fphys = recRef.f_phys_max;

        yFeas = nan(size(fFine));
        yCap = nan(size(fFine));

        for k = 1:numel(fFine)
            fReq = fFine(k);

            if fReq <= fphys
                rec = evaluate_design(fam, N, s, beta_deg, fReq, sigmaList(row), cfg, ...
                    'StoreSeries', false);
                yFeas(k) = rec.rmse_xy;
            end

            fEff = min(fReq, fphys);
            rec2 = evaluate_design(fam, N, s, beta_deg, fEff, sigmaList(row), cfg, ...
                'StoreSeries', false);
            yCap(k) = rec2.rmse_xy;
        end

        plot(fFine, yFeas, '-', 'LineWidth', 2.0, ...
            'Color', C(i,:), ...
            'DisplayName', sprintf('%s feasible', fam));

        plot(fFine, yCap, '--', 'LineWidth', 1.5, ...
            'Color', C(i,:), ...
            'DisplayName', sprintf('%s capped', fam));

        xline(fphys, ':', 'Color', C(i,:), 'LineWidth', 1.2, ...
            'HandleVisibility','off');

        OUT.(sprintf('%s_fphys', fam)) = fphys;
        OUT.(sprintf('%s_feas_sigma%d', fam, row)) = yFeas;
        OUT.(sprintf('%s_cap_sigma%d', fam, row)) = yCap;

        if row == 1
            one = table(string(fam), fphys, ...
                'VariableNames', {'family','f_phys_max'});
            fmaxTable = [fmaxTable; one]; %#ok<AGROW>
        end
    end

    xlabel('Requested acoustic update rate / Hz');
    ylabel('Horizontal RMSE lower bound / m');
    title(sprintf('%s', sigmaName{row}));
    legend('Location','northeast');
end

nexttile; axis off;
txt = ["Physical acoustic update-rate upper bounds"; ...
       " "; ...
       compose("%s: %.3f Hz", fmaxTable.family, fmaxTable.f_phys_max)];

text(0.02,0.95,txt,'VerticalAlignment','top','FontSize',12);

OUT.fmaxTable = fmaxTable;
assignin('base','fig4_fmax_table',fmaxTable);

sgtitle('Figure 4 revised  Acoustic update rate, feasible region, and saturation');

end
