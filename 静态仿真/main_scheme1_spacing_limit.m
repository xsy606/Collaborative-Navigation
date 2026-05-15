function OUT = main_scheme1_spacing_limit()
% Scheme 1 extension: diagnose useful spacing upper limit.
%
% For each family and GNSS level, compute:
%   s_min   : minimum feasible spacing satisfying target
%   s_opt   : spacing yielding minimum RMSE after optimizing other variables
%   s_upper : first spacing after which increasing spacing no longer improves RMSE

close all;
cfg = default_config();

families = {'line','wedge','polygon'};
gnssGrid = cfg.grid.gnss;
sGrid = cfg.grid.s;

tolImprove = 0.01;  % 1% improvement threshold

OUT = struct();

for iFam = 1:numel(families)
    fam = families{iFam};

    OUT.(fam).bestRmseByS = nan(numel(gnssGrid), numel(sGrid));
    OUT.(fam).s_min = nan(size(gnssGrid));
    OUT.(fam).s_opt = nan(size(gnssGrid));
    OUT.(fam).s_upper = nan(size(gnssGrid));

    for ig = 1:numel(gnssGrid)
        sg = gnssGrid(ig);

        for is = 1:numel(sGrid)
            s = sGrid(is);

            bestRmse = inf;
            feasibleHit = false;

            for N = cfg.grid.N
                betaSet = local_beta_set(fam, cfg);

                for beta = betaSet
                    for f = cfg.acoustic.f_grid
                        rec = evaluate_design(fam, N, s, beta, f, sg, cfg, ...
                            'StoreSeries', false);

                        if rec.is_feasible
                            feasibleHit = true;
                            bestRmse = min(bestRmse, rec.rmse_xy);
                        end
                    end
                end
            end

            if feasibleHit
                OUT.(fam).bestRmseByS(ig,is) = bestRmse;
            end
        end

        y = OUT.(fam).bestRmseByS(ig,:);

        idxFeasTarget = find(y <= cfg.requirement.rmse_xy, 1, 'first');
        if ~isempty(idxFeasTarget)
            OUT.(fam).s_min(ig) = sGrid(idxFeasTarget);
        end

        [~, idxOpt] = min(y);
        if isfinite(y(idxOpt))
            OUT.(fam).s_opt(ig) = sGrid(idxOpt);
        end

        % s_upper: after the optimum, first location where next spacing
        % does not improve by more than tolImprove.
        idxUpper = nan;
        for k = idxOpt:(numel(sGrid)-1)
            if ~isfinite(y(k)) || ~isfinite(y(k+1))
                continue;
            end

            relImprove = (y(k) - y(k+1)) / max(y(k), 1e-9);

            if relImprove < tolImprove
                idxUpper = k;
                break;
            end
        end

        if isfinite(idxUpper)
            OUT.(fam).s_upper(ig) = sGrid(idxUpper);
        end
    end
end

figure('Color','w','Position',[80 80 1300 780]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

nexttile; hold on; grid on; box on;
for i = 1:numel(families)
    fam = families{i};
    plot(gnssGrid, OUT.(fam).s_min, '-o', 'LineWidth', 1.8, 'DisplayName', fam);
end
xlabel('\sigma_{GNSS} / m');
ylabel('s_{min} / m');
title('Minimum feasible spacing');
legend('Location','northwest');

nexttile; hold on; grid on; box on;
for i = 1:numel(families)
    fam = families{i};
    plot(gnssGrid, OUT.(fam).s_opt, '-o', 'LineWidth', 1.8, 'DisplayName', fam);
end
xlabel('\sigma_{GNSS} / m');
ylabel('s_{opt} / m');
title('Best spacing after optimizing N, \beta, f');
legend('Location','northwest');

nexttile; hold on; grid on; box on;
for i = 1:numel(families)
    fam = families{i};
    plot(gnssGrid, OUT.(fam).s_upper, '-o', 'LineWidth', 1.8, 'DisplayName', fam);
end
xlabel('\sigma_{GNSS} / m');
ylabel('s_{upper} / m');
title('Useful upper spacing limit');
legend('Location','northwest');

nexttile; hold on; grid on; box on;
for i = 1:numel(families)
    fam = families{i};
    y = OUT.(fam).bestRmseByS(1,:);
    plot(sGrid, y, '-o', 'LineWidth', 1.8, ...
        'DisplayName', sprintf('%s @ GNSS %.1f m', fam, gnssGrid(1)));
end
xlabel('Spacing s / m');
ylabel('Best RMSE over N,\beta,f / m');
title('Example RMSE-spacing profile');
legend('Location','best');

sgtitle('Scheme 1 extension  Spacing useful upper limit');

assignin('base','scheme1_spacing_limit_out',OUT);

end

function betaSet = local_beta_set(fam, cfg)
if strcmpi(fam, 'wedge')
    betaSet = cfg.grid.beta_deg;
else
    betaSet = cfg.example.beta_deg;
end
end
