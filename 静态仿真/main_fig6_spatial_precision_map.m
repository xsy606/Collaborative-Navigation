function OUT = main_fig6_spatial_precision_map()
% Figure 6: Spatial precision map for different AUV relative positions.
%
% This figure diagnoses whether polygon is only advantageous when the AUV
% lies inside or near the polygon enclosure.

close all;
paper_style();
cfg = default_config('paper');

families = {'line','wedge','polygon'};
familyName = {'Line','Wedge','Polygon'};
familyColors = zeros(numel(families),3);
for iFam = 1:numel(families)
    st = family_style(families{iFam});
    familyColors(iFam,:) = st.color;
end

N = cfg.example.N;
s = cfg.example.s;
beta_deg = cfg.example.beta_deg;
sigma_gnss = cfg.meas.gnss_sigma_default;

xGrid = linspace(-650, 850, 61);
yGrid = linspace(-650, 650, 53);

[X,Y] = meshgrid(xGrid, yGrid);

OUT = struct();
OUT.xGrid = xGrid;
OUT.yGrid = yGrid;
OUT.sigma_gnss = sigma_gnss;

RMSE = nan([size(X), numel(families)]);

for iFam = 1:numel(families)
    fam = families{iFam};

    A = build_formation(fam, N, s, ...
        struct('beta_deg', beta_deg, 'rot_deg', 0));

    for ix = 1:numel(xGrid)
        for iy = 1:numel(yGrid)
            p = [X(iy,ix); Y(iy,ix)];

            [Jxy, ~] = range_snapshot_info_schur(p, A, sigma_gnss, cfg);
            Pxy = pinv(Jxy);
            met = metrics_from_P(Pxy);

            RMSE(iy,ix,iFam) = met.rmse_xy;
        end
    end

    OUT.(fam).anchors = A;
    OUT.(fam).rmseMap = RMSE(:,:,iFam);
end

% Best-family map
[bestRmse, bestIdx] = min(RMSE, [], 3);
OUT.bestRmse = bestRmse;
OUT.bestIdx = bestIdx;

mapLim = local_color_limit(RMSE);

new_paper_figure('Fig6_spatial_precision_maps', [60 60 1450 760]);
tiledlayout(2,3,'TileSpacing','compact','Padding','compact');

for iFam = 1:numel(families)
    fam = families{iFam};
    A = OUT.(fam).anchors;
    st = family_style(fam);

    nexttile; hold on; box on;
    contourf(X, Y, RMSE(:,:,iFam), 32, 'LineColor','none');
    colormap(gca, parula(256));
    clim(mapLim);
    cb = colorbar;
    cb.Label.String = 'RMSE / m';
    contour(X, Y, RMSE(:,:,iFam), [cfg.requirement.rmse_xy cfg.requirement.rmse_xy], ...
        'w--', 'LineWidth', 1.4);
    scatter(A(:,1), A(:,2), 74, ...
        'MarkerFaceColor', [0.08 0.08 0.08], ...
        'MarkerEdgeColor', 'w', ...
        'LineWidth', 0.9);
    scatter(0, 0, 110, 'p', ...
        'MarkerFaceColor', [0.85 0.05 0.05], ...
        'MarkerEdgeColor', 'w', ...
        'LineWidth', 0.9);

    local_plot_hull(A, st.color);

    xlabel('AUV relative x / m');
    ylabel('AUV relative y / m');
    title(sprintf('%s RMSE map', familyName{iFam}));
    axis equal tight;
    apply_axis_style(gca);
end

for iFam = 1:numel(families)
    fam = families{iFam};
    A = OUT.(fam).anchors;

    nexttile; hold on; box on;
    surf(X, Y, RMSE(:,:,iFam), 'EdgeColor','none');
    shading interp;
    colormap(gca, parula(256));
    clim(mapLim);
    scatter3(A(:,1), A(:,2), zeros(size(A,1),1), 70, ...
        'MarkerFaceColor', [0.08 0.08 0.08], ...
        'MarkerEdgeColor', 'w', ...
        'LineWidth', 0.9);
    scatter3(0, 0, 0, 110, 'p', ...
        'MarkerFaceColor', [0.85 0.05 0.05], ...
        'MarkerEdgeColor', 'w', ...
        'LineWidth', 0.9);

    xlabel('x / m');
    ylabel('y / m');
    zlabel('RMSE / m');
    title(sprintf('%s RMSE surface', familyName{iFam}));
    view(45,35);
    grid on;
    apply_axis_style(gca);
end

sgtitle(sprintf('Figure 6  Spatial precision map, \\sigma_{GNSS}=%.2f m', sigma_gnss));

new_paper_figure('Fig6_best_family_regions', [120 120 860 650]);
hold on; box on;
imagesc(xGrid, yGrid, bestIdx);
set(gca,'YDir','normal');
axis equal tight;
colormap(gca, familyColors);
cb = colorbar('Ticks',1:3,'TickLabels',familyName);
cb.Label.String = 'Best family class';
contour(X, Y, bestRmse, 10, ...
    'Color',[0.12 0.12 0.12], ...
    'LineWidth', 0.7);
contour(X, Y, bestRmse, [cfg.requirement.rmse_xy cfg.requirement.rmse_xy], ...
    'w--', 'LineWidth', 1.5);
scatter(0, 0, 115, 'p', ...
    'MarkerFaceColor', [0.85 0.05 0.05], ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', 0.9, ...
    'DisplayName','AUV reference');
contour(X, Y, bestIdx, [1.5 2.5], ...
    'Color','w', ...
    'LineWidth', 1.0, ...
    'HandleVisibility','off');

xlabel('AUV relative x / m');
ylabel('AUV relative y / m');
title('Best family regions under equal nominal settings');
subtitle('Discrete colors encode winner class, not RMSE magnitude');
legend('Location','eastoutside');
apply_axis_style(gca);

assignin('base','fig6_spatial_precision_out',OUT);

end

function local_plot_hull(A, color)
try
    if rank(A - mean(A,1)) >= 2
        k = convhull(A(:,1), A(:,2));
        plot(A(k,1), A(k,2), '-', ...
            'Color', color, ...
            'LineWidth', 1.5);
    end
catch
end
end

function lim = local_color_limit(X)
x = X(isfinite(X));
if isempty(x)
    lim = [0 1];
    return;
end

x = sort(x(:));
hiIdx = max(1, min(numel(x), round(0.95 * numel(x))));
hi = x(hiIdx);
lim = [0, max(hi, eps)];
end
