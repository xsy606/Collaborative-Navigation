function OUT = main_paper_pareto_analysis(mode)
%MAIN_PAPER_PARETO_ANALYSIS Multi-objective formation-design analysis.

close all;
paper_style();
if nargin < 1
    cfg = default_config();
else
    cfg = default_config(mode);
end

families = {'line','wedge','polygon'};
sigma_gnss = cfg.meas.gnss_sigma_default;

rows = [];
records = {};

for iFam = 1:numel(families)
    fam = families{iFam};

    for N = cfg.grid.N
        for s = cfg.grid.s
            betaSet = local_beta_set(fam, cfg);

            for beta = betaSet
                for f = cfg.acoustic.f_grid
                    rec = evaluate_design(fam, N, s, beta, f, sigma_gnss, cfg, ...
                        'StoreSeries', false);
                    [~, bd] = family_cost(fam, rec.anchors, N, f, cfg);

                    one = struct();
                    one.family = string(fam);
                    one.N = N;
                    one.s = s;
                    one.beta_deg = beta;
                    one.f_ac = f;
                    one.rmse_xy = rec.rmse_xy;
                    one.area95 = rec.area95;
                    one.cost = rec.cost;
                    one.footprint = bd.footprint;
                    one.f_phys_max = rec.f_phys_max;
                    one.is_feasible = rec.is_feasible;
                    one.meets_target = rec.rmse_xy <= cfg.requirement.rmse_xy;

                    rows = [rows; struct2table(one)]; %#ok<AGROW>
                    records{end+1} = rec; %#ok<AGROW>
                end
            end
        end
    end
end

obj = [rows.rmse_xy, rows.cost, rows.footprint, rows.f_ac];
mask = false(height(rows),1);
idxFeasible = rows.is_feasible;
mask(idxFeasible) = pareto_front_mask(obj(idxFeasible,:), ["min","min","min","min"]);
rows.is_pareto = mask;

idxTarget = rows.is_feasible & rows.meets_target;
maskTarget = false(height(rows),1);
if any(idxTarget)
    objTarget = [rows.cost, rows.footprint, rows.f_ac, rows.rmse_xy];
    maskTarget(idxTarget) = pareto_front_mask(objTarget(idxTarget,:), ...
        ["min","min","min","min"]);
end
rows.is_target_pareto = maskTarget;

OUT = struct();
OUT.cfg = cfg;
OUT.sigma_gnss = sigma_gnss;
OUT.table = rows;
OUT.records = records;
OUT.paretoTable = rows(mask,:);
OUT.targetParetoTable = rows(maskTarget,:);

assignin('base','paper_pareto_out',OUT);
assignin('base','paper_pareto_table',OUT.paretoTable);

disp('===== Paper Pareto-front designs =====');
disp(sortrows(OUT.paretoTable, {'rmse_xy','cost'}));
disp('===== Target-feasible Pareto designs (recommended comparison set) =====');
disp(sortrows(OUT.targetParetoTable, {'cost','rmse_xy'}));

new_paper_figure('Paper_pareto_rmse_cost', [100 100 900 620]);
hold on; grid on; box on;
pal = paper_palette();

for iFam = 1:numel(families)
    fam = families{iFam};
    st = family_style(fam);
    idx = strcmpi(rows.family, fam) & rows.is_feasible;
    scatter(rows.cost(idx), rows.rmse_xy(idx), 28, ...
        'MarkerFaceColor', lighten_color(st.color, 0.45), ...
        'MarkerEdgeColor', 'none', ...
        'MarkerFaceAlpha', 0.20, ...
        'DisplayName', sprintf('%s candidates', st.name));

    idxP = idx & rows.is_pareto & ~rows.is_target_pareto;
    scatter(rows.cost(idxP), rows.rmse_xy(idxP), 72, ...
        'MarkerEdgeColor', lighten_color(st.color, 0.10), ...
        'MarkerFaceColor', 'w', ...
        'LineWidth', 1.5, ...
        'DisplayName', sprintf('%s feasible Pareto', st.name));

    idxTP = idx & rows.is_target_pareto;
    scatter(rows.cost(idxTP), rows.rmse_xy(idxTP), 105, ...
        'MarkerEdgeColor', 'k', ...
        'MarkerFaceColor', st.color, ...
        'LineWidth', 1.1, ...
        'DisplayName', sprintf('%s target-Pareto', st.name));
end

xlabel('Cost proxy');
ylabel('Horizontal RMSE lower bound / m');
title(sprintf('Feasible and target-feasible Pareto fronts at \\sigma_{GNSS}=%.1f m', sigma_gnss));
visibleRmse = rows.rmse_xy(rows.is_feasible & rows.rmse_xy < 8);
if isempty(visibleRmse)
    visibleRmse = rows.rmse_xy(rows.is_feasible);
end
ylim([0, max([visibleRmse; cfg.requirement.rmse_xy])*1.12]);
plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE', 'Color', pal.target);
local_label_recommended_designs(rows);
legend('Location','northeastoutside');
apply_axis_style(gca);

new_paper_figure('Paper_pareto_footprint_rate', [130 130 900 620]);
hold on; grid on; box on;

idxP = rows.is_target_pareto & rows.is_feasible;
scatter(rows.footprint(idxP), rows.f_ac(idxP), 82, rows.rmse_xy(idxP), ...
    'filled', 'MarkerEdgeColor','w', 'LineWidth',0.8);
cb = colorbar;
cb.Label.String = 'RMSE / m';
xlabel('Formation footprint / m');
ylabel('Acoustic update rate / Hz');
title('Target-feasible Pareto designs: footprint-rate tradeoff colored by RMSE');
apply_axis_style(gca);

end

function local_label_recommended_designs(rows)
idx = find(rows.is_target_pareto);
if isempty(idx)
    return;
end

T = rows(idx,:);
T = sortrows(T, {'cost','rmse_xy'});
nLabel = min(3, height(T));

for k = 1:nLabel
    st = family_style(char(T.family(k)));
    annotate_best_point(gca, T.cost(k), T.rmse_xy(k), ...
        sprintf('%s N%d s%d', st.name, T.N(k), T.s(k)), st.color);
end
end

function betaSet = local_beta_set(fam, cfg)
if strcmpi(fam, 'wedge')
    betaSet = cfg.grid.beta_deg;
else
    betaSet = cfg.example.beta_deg;
end
end
