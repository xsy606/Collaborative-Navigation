function S = main_fig1_ellipse()
% Figure 1:
%   (a) physical formation + error ellipse
%   (b) normalized ellipse + metrics

close all;
cfg = default_config('paper');

families = {'line','wedge','polygon'};
titles = {'Line','Wedge','Polygon'};
sigmaList = [cfg.meas.rtk_sigma, cfg.meas.gnss_sigma_default];
sigmaName = {'RTK-like','GNSS-degraded'};

S = struct();

% Use common feasible rate for fair comparison
fphysAll = zeros(1, numel(families));
for i = 1:numel(families)
    param = struct('beta_deg', cfg.example.beta_deg, 'rot_deg', 180/cfg.example.N);
    A = build_formation(families{i}, cfg.example.N, cfg.example.s, param);
    fphysAll(i) = acoustic_physical_limit(A, cfg);
end
fCommon = min(cfg.example.f, 0.95 * min(fphysAll));

figure('Color','w','Position',[50 50 1350 720]);
tiledlayout(2,3,'TileSpacing','compact','Padding','compact');

for row = 1:2
    for col = 1:3
        fam = families{col};
        rec = evaluate_design(fam, cfg.example.N, cfg.example.s, ...
            cfg.example.beta_deg, fCommon, sigmaList(row), cfg, ...
            'StoreSeries', false);

        nexttile; hold on; grid on; box on; axis equal;

        scatter(rec.anchors(:,1), rec.anchors(:,2), 60, 'filled');
        scatter(cfg.target.nominal_state(1), cfg.target.nominal_state(2), ...
            90, 'p', 'filled');

        for j = 1:size(rec.anchors,1)
            plot([rec.anchors(j,1), cfg.target.nominal_state(1)], ...
                 [rec.anchors(j,2), cfg.target.nominal_state(2)], ...
                 '--', 'Color', [0.75 0.75 0.75]);
        end

        plot_error_ellipse(cfg.target.nominal_state(1:2), rec.Pxy, ...
            'LineWidth', 2);

        xlabel('x / m');
        ylabel('y / m');
        title(sprintf('%s | %s', titles{col}, sigmaName{row}));

        text(0.02,0.98, sprintf('RMSE=%.2f m\nMajor95=%.2f m\nArea95=%.2f m^2', ...
            rec.rmse_xy, rec.major95, rec.area95), ...
            'Units','normalized','VerticalAlignment','top', ...
            'BackgroundColor','w','Margin',5);

        S.(sprintf('%s_%d', fam, row)) = rec;
    end
end

sgtitle('Figure 1a  Physical formation and 95% error ellipse');

% Normalized ellipse and metric bars
figure('Color','w','Position',[80 80 1350 720]);
tiledlayout(2,4,'TileSpacing','compact','Padding','compact');

for row = 1:2
    major = zeros(1,3);
    minor = zeros(1,3);
    area = zeros(1,3);
    condn = zeros(1,3);

    nexttile((row-1)*4+1); hold on; grid on; box on; axis equal;
    for col = 1:3
        rec = S.(sprintf('%s_%d', families{col}, row));
        plot_error_ellipse([0;0], rec.Pxy, 'LineWidth', 2, ...
            'DisplayName', titles{col});

        major(col) = rec.major95;
        minor(col) = rec.minor95;
        area(col) = rec.area95;
        condn(col) = rec.condnum;
    end
    scatter(0,0,70,'p','filled');
    xlabel('x error / m');
    ylabel('y error / m');
    title(sprintf('Normalized ellipses | %s', sigmaName{row}));
    legend('Location','best');

    nexttile((row-1)*4+2);
    bar([major(:), minor(:)]);
    set(gca,'XTickLabel',titles);
    grid on; box on;
    ylabel('m');
    title('Ellipse axes');
    legend({'major95','minor95'},'Location','northwest');

    nexttile((row-1)*4+3);
    bar(area);
    set(gca,'XTickLabel',titles);
    grid on; box on;
    ylabel('m^2');
    title('Ellipse area');

    nexttile((row-1)*4+4);
    bar(condn);
    set(gca,'XTickLabel',titles);
    grid on; box on;
    ylabel('condition number');
    title('Anisotropy');
end

sgtitle('Figure 1b  Normalized error ellipse metrics');

end
