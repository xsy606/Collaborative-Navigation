function OUT = main_scheme2_robust()
% Scheme 2 revised: robust fixed strategy selection with infeasible intervals
% and stacked cost breakdown.

close all;
cfg = default_config();
gnss = cfg.grid.gnss;

robust = find_global_robust_strategy(cfg, gnss);
cand = robust.allFamilies;

OUT.robust = robust;
OUT.candidates = cand;

nC = numel(cand);

Family = strings(nC,1);
Ncol = zeros(nC,1);
Scol = zeros(nC,1);
Bcol = zeros(nC,1);
Fcol = zeros(nC,1);
Fphys = zeros(nC,1);
Foot = zeros(nC,1);
CostShip = zeros(nC,1);
CostFoot = zeros(nC,1);
CostRate = zeros(nC,1);
CostFootExcess = zeros(nC,1);
CostTotal = zeros(nC,1);
P90 = zeros(nC,1);
Worst = zeros(nC,1);
Meanv = zeros(nC,1);
Score = zeros(nC,1);
InfeasibleInterval = strings(nC,1);

for i = 1:nC
    c = cand{i};

    [~, bd] = family_cost(c.family, c.anchors, c.N, c.f_ac, cfg);

    Family(i) = string(c.family);
    Ncol(i) = c.N;
    Scol(i) = c.s;
    Bcol(i) = c.beta_deg;
    Fcol(i) = c.f_ac;
    Fphys(i) = c.f_phys_max;
    Foot(i) = bd.footprint;

    CostShip(i) = bd.c_ship;
    CostFoot(i) = bd.c_foot;
    CostRate(i) = bd.c_rate;
    CostFootExcess(i) = bd.c_foot_excess;
    CostTotal(i) = bd.total;

    P90(i) = c.p90_norm_rmse;
    Worst(i) = c.worst_norm_rmse;
    Meanv(i) = c.mean_norm_rmse;
    Score(i) = c.score;

    InfeasibleInterval(i) = local_infeasible_interval_text(gnss, c.feasibleVec);
end

Tbl = table(Family,Ncol,Scol,Bcol,Fcol,Fphys,Foot, ...
    CostShip,CostFoot,CostRate,CostFootExcess,CostTotal,P90,Worst,Meanv,Score,InfeasibleInterval);

OUT.summaryTable = Tbl;

assignin('base','scheme2_summary_table',Tbl);
disp('===== Scheme 2 revised summary table =====');
disp(Tbl);

figure('Color','w','Position',[60 60 1450 850]);
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

% (a) RMSE curves
nexttile; hold on; grid on; box on;
for i = 1:nC
    plot(gnss, cand{i}.rmseVec, '-o', 'LineWidth', 1.8, ...
        'DisplayName', char(cand{i}.family));
end
yline(cfg.requirement.rmse_xy, '--', 'target');
xlabel('\sigma_{GNSS} / m');
ylabel('Horizontal RMSE lower bound / m');
title('Scheme 2(a) Family-best fixed strategies');
legend('Location','northwest');

% (b) Exceedance
nexttile; hold on; grid on; box on;
for i = 1:nC
    plot(gnss, cand{i}.rmseVec - cfg.requirement.rmse_xy, '-o', ...
        'LineWidth', 1.8, 'DisplayName', char(cand{i}.family));
end
yline(0, '--', 'target');
xlabel('\sigma_{GNSS} / m');
ylabel('Exceedance over target / m');
title('Scheme 2(b) Exceedance over target');
legend('Location','northwest');

% (c) Stacked cost
nexttile; hold on; grid on; box on;
Y = [CostShip, CostFoot, CostRate, CostFootExcess];
bar(Y, 'stacked');
set(gca,'XTick',1:nC,'XTickLabel',cellstr(Family));
ylabel('Cost proxy');
title('Scheme 2(c) Cost breakdown');
legend({'ship-count','footprint','update-rate','excess-footprint'},'Location','northwest');

% (d) Summary text
nexttile; axis off;
txt = {
    sprintf('Selected robust family: %s', char(robust.family))
    sprintf('N = %d', robust.N)
    sprintf('s = %.1f m', robust.s)
    sprintf('\\beta = %.1f deg', robust.beta_deg)
    sprintf('f = %.2f Hz', robust.f_ac)
    sprintf('f_{phys,max} = %.2f Hz', robust.f_phys_max)
    sprintf('cost = %.2f', robust.cost)
    sprintf('p90 normalized RMSE = %.3f', robust.p90_norm_rmse)
    sprintf('worst normalized RMSE = %.3f', robust.worst_norm_rmse)
    sprintf('score = %.3f', robust.score)
    sprintf('infeasible interval = %s', char(local_infeasible_interval_text(gnss, robust.feasibleVec)))
    };

text(0.03,0.95,txt,'FontSize',12,'VerticalAlignment','top');
title('Scheme 2(d) Selected robust strategy');

sgtitle('Scheme 2 revised  Robust fixed-strategy selection');

end

function txt = local_infeasible_interval_text(gnss, feasibleVec)
bad = ~feasibleVec(:).';

if ~any(bad)
    txt = "none";
    return;
end

idx = find(bad);
segments = {};
startIdx = idx(1);
prevIdx = idx(1);

for k = 2:numel(idx)
    if idx(k) == prevIdx + 1
        prevIdx = idx(k);
    else
        segments{end+1} = sprintf('[%.2f, %.2f]', gnss(startIdx), gnss(prevIdx)); %#ok<AGROW>
        startIdx = idx(k);
        prevIdx = idx(k);
    end
end

segments{end+1} = sprintf('[%.2f, %.2f]', gnss(startIdx), gnss(prevIdx));
txt = string(strjoin(segments, ', '));
end
