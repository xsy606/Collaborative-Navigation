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
footprintRef = cfg.example.footprint;
beta_deg = cfg.example.beta_deg;
sigma_gnss = cfg.meas.gnss_sigma_default;

if strcmpi(cfg.run.mode, 'paper')
    xGrid = linspace(-650, 850, 181);
    yGrid = linspace(-650, 650, 157);
else
    xGrid = linspace(-650, 850, 91);
    yGrid = linspace(-650, 650, 79);
end

[X,Y] = meshgrid(xGrid, yGrid);

OUT = struct();
OUT.xGrid = xGrid;
OUT.yGrid = yGrid;
OUT.sigma_gnss = sigma_gnss;
OUT.footprint = footprintRef;

RMSE = nan([size(X), numel(families)]);

for iFam = 1:numel(families)
    fam = families{iFam};

    A = build_formation_with_footprint(fam, N, footprintRef, ...
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

colorStats = local_color_stats(RMSE, families);
OUT.colorStats = colorStats;
disp('===== Figure 6 RMSE color-scale diagnostics =====');
disp(colorStats);

mapLim = [0, max(cfg.requirement.rmse_xy, colorStats.GlobalP95(1))];
OUT.colorLimit = mapLim;

new_paper_figure('Fig6_spatial_precision_maps', [60 60 1450 760]);
tiledlayout(2,3,'TileSpacing','compact','Padding','compact');

for iFam = 1:numel(families)
    fam = families{iFam};
    A = OUT.(fam).anchors;
    st = family_style(fam);

    nexttile; hold on; box on;
    Z = min(RMSE(:,:,iFam), mapLim(2));
    contourf(X, Y, Z, 40, 'LineColor','none');
    colormap(gca, parula(256));
    clim(mapLim);
    cb = colorbar;
    cb.Label.String = sprintf('RMSE / m (clipped at %.1f)', mapLim(2));
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
    if colorStats.Max(iFam) > mapLim(2)
        text(0.02, 0.96, sprintf('max %.1g m, clipped', colorStats.Max(iFam)), ...
            'Units','normalized', ...
            'VerticalAlignment','top', ...
            'BackgroundColor','w', ...
            'Margin',4, ...
            'Color',[0.15 0.15 0.15]);
    end
    axis equal tight;
    apply_axis_style(gca);
end

for iFam = 1:numel(families)
    fam = families{iFam};
    A = OUT.(fam).anchors;

    nexttile; hold on; box on;
    Z = min(RMSE(:,:,iFam), mapLim(2));
    surf(X, Y, Z, 'EdgeColor','none');
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
    zlabel(sprintf('RMSE / m (clipped at %.1f)', mapLim(2)));
    title(sprintf('%s clipped RMSE surface', familyName{iFam}));
    view(45,35);
    grid on;
    apply_axis_style(gca);
end

sgtitle(sprintf('Figure 6  Fixed-footprint spatial precision map, footprint=%.0f m, \\sigma_{GNSS}=%.2f m', ...
    footprintRef, sigma_gnss));

new_paper_figure('Fig6_best_family_regions', [120 120 860 650]);
hold on; box on;
contourf(X, Y, bestIdx, 0.5:1:3.5, ...
    'LineColor','none');
set(gca,'YDir','normal');
axis equal tight;
colormap(gca, familyColors);
clim([0.5 3.5]);
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
    'LineWidth', 1.2, ...
    'HandleVisibility','off');
local_plot_pairwise_boundaries(X, Y, RMSE, familyColors);

hLeg = gobjects(numel(families)+1,1);
for iFam = 1:numel(families)
    hLeg(iFam) = scatter(nan, nan, 90, 's', ...
        'MarkerFaceColor', familyColors(iFam,:), ...
        'MarkerEdgeColor', 'w', ...
        'LineWidth', 0.8, ...
        'DisplayName', sprintf('%s best', familyName{iFam}));
end
hLeg(end) = scatter(nan, nan, 95, 'p', ...
    'MarkerFaceColor', [0.85 0.05 0.05], ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', 0.9, ...
    'DisplayName','AUV reference');

xlabel('AUV relative x / m');
ylabel('AUV relative y / m');
title('Best family regions under fixed footprint');
subtitle(sprintf('Region color indicates the winning family, footprint = %.0f m', footprintRef));
legend(hLeg, 'Location','eastoutside');
apply_axis_style(gca);

new_paper_figure('Fig6_best_family_masks', [150 150 1180 390]);
tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
for iFam = 1:numel(families)
    nexttile; hold on; box on;
    mask = bestIdx == iFam;
    contourf(X, Y, double(mask), [-0.5 0.5 1.5], ...
        'LineColor','none');
    set(gca,'YDir','normal');
    colormap(gca, [0.94 0.95 0.96; familyColors(iFam,:)]);
    clim([0 1]);
    contour(X, Y, bestRmse, [cfg.requirement.rmse_xy cfg.requirement.rmse_xy], ...
        'Color',[0.18 0.18 0.18], 'LineStyle','--', 'LineWidth', 1.2);
    scatter(0, 0, 95, 'p', ...
        'MarkerFaceColor', [0.85 0.05 0.05], ...
        'MarkerEdgeColor', 'w', ...
        'LineWidth', 0.9);
    xlabel('AUV relative x / m');
    ylabel('AUV relative y / m');
    title(sprintf('%s-winning region', familyName{iFam}));
    axis equal tight;
    apply_axis_style(gca);
end
sgtitle(sprintf('Winner masks under fixed footprint: %.0f m', footprintRef));

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

function stats = local_color_stats(RMSE, families)
nFam = numel(families);
Family = strings(nFam,1);
Min = nan(nFam,1);
Median = nan(nFam,1);
P90 = nan(nFam,1);
P95 = nan(nFam,1);
P99 = nan(nFam,1);
Max = nan(nFam,1);

for iFam = 1:nFam
    x = RMSE(:,:,iFam);
    x = x(isfinite(x));
    Family(iFam) = string(families{iFam});
    Min(iFam) = min(x);
    Median(iFam) = local_quantile(x, 0.50);
    P90(iFam) = local_quantile(x, 0.90);
    P95(iFam) = local_quantile(x, 0.95);
    P99(iFam) = local_quantile(x, 0.99);
    Max(iFam) = max(x);
end

allVal = RMSE(isfinite(RMSE));
GlobalP95 = repmat(local_quantile(allVal, 0.95), nFam, 1);
GlobalMax = repmat(max(allVal), nFam, 1);
stats = table(Family, Min, Median, P90, P95, P99, Max, GlobalP95, GlobalMax);
end

function q = local_quantile(x, alpha)
x = sort(x(:));
if isempty(x)
    q = nan;
    return;
end
if numel(x) == 1
    q = x;
    return;
end

pos = 1 + (numel(x)-1)*alpha;
lo = floor(pos);
hi = ceil(pos);
if lo == hi
    q = x(lo);
else
    q = x(lo) + (x(hi)-x(lo)) * (pos-lo);
end
end

function local_plot_pairwise_boundaries(X, Y, RMSE, familyColors)
pairs = [1 2; 1 3; 2 3];
for i = 1:size(pairs,1)
    a = pairs(i,1);
    b = pairs(i,2);
    C = 0.5 * (familyColors(a,:) + familyColors(b,:));
    contour(X, Y, RMSE(:,:,a) - RMSE(:,:,b), [0 0], ...
        'Color', max(min(C * 0.7, 1), 0), ...
        'LineWidth', 1.1, ...
        'LineStyle','-', ...
        'HandleVisibility','off');
end
end
