function OUT = main_paper_baseline_ablation(mode)
%MAIN_PAPER_BASELINE_ABLATION Compare cooperative designs with baselines.
%
% The experiment reports two levels of baselines:
%   1) sanity baselines: dead-reckoning and single-USV ranging;
%   2) fair baselines: unoptimized example formation and random layouts
%      with resource settings matched to the robust strategy.

close all;
paper_style();
pal = paper_palette();
if nargin < 1
    cfg = default_config();
else
    cfg = default_config(mode);
end

gnss = cfg.grid.gnss;
robust = find_global_robust_strategy(cfg, gnss);
cand = robust.allFamilies;
nC = numel(cand);

dr = dead_reckoning_bound(cfg);
deadRmse = dr.rmse_xy * ones(size(gnss));

singleRmse = nan(size(gnss));
singleFeasible = false(size(gnss));

for k = 1:numel(gnss)
    A1 = build_formation('line', 1, 0, struct());
    f1 = min(cfg.example.f, 0.95 * acoustic_physical_limit(A1, cfg));
    rec1 = evaluate_design('line', 1, 0, cfg.example.beta_deg, f1, gnss(k), cfg, ...
        'StoreSeries', false);
    singleRmse(k) = rec1.rmse_xy;
    singleFeasible(k) = rec1.is_feasible;
end

familyRmse = nan(numel(gnss), nC);
Family = strings(nC,1);
WorstRMSE = zeros(nC,1);
P90RMSE = zeros(nC,1);
MeanGainVsDR = zeros(nC,1);
AllFeasible = false(nC,1);
Cost = zeros(nC,1);
Score = zeros(nC,1);

for i = 1:nC
    familyRmse(:,i) = cand{i}.rmseVec(:);
    Family(i) = string(cand{i}.family);
    WorstRMSE(i) = max(cand{i}.rmseVec);
    P90RMSE(i) = local_quantile(cand{i}.rmseVec(:), 0.9);
    MeanGainVsDR(i) = mean((deadRmse(:) - cand{i}.rmseVec(:)) ./ deadRmse(:));
    AllFeasible(i) = cand{i}.is_feasible_all;
    Cost(i) = cand{i}.cost;
    Score(i) = cand{i}.score;
end

% Fair baselines with comparable acoustic/cooperative resources.
exampleBaseline = local_eval_family_curve('wedge', cfg.example.N, cfg.example.s, ...
    cfg.example.beta_deg, cfg.example.f, gnss, cfg);

robustN = robust.N;
robustF = robust.f_ac;
robustFoot = local_footprint(robust.anchors);

compactS = min(cfg.grid.s);
compactBaseline = local_eval_family_curve(char(robust.family), robustN, compactS, ...
    robust.beta_deg, robustF, gnss, cfg);

randomBaseline = local_eval_random_layout_curve(robustN, robustFoot, robustF, gnss, cfg, 12);

Baseline = ["dead-reckoning"; "single-USV"];
BaselineWorstRMSE = [max(deadRmse); max(singleRmse)];
BaselineP90RMSE = [local_quantile(deadRmse(:), 0.9); local_quantile(singleRmse(:), 0.9)];
BaselineMeanGainVsDR = [0; mean((deadRmse(:) - singleRmse(:)) ./ deadRmse(:))];
BaselineAllFeasible = [true; all(singleFeasible)];

TblFamily = table(Family,WorstRMSE,P90RMSE,MeanGainVsDR,AllFeasible,Cost,Score);
TblBaseline = table(Baseline,BaselineWorstRMSE,BaselineP90RMSE, ...
    BaselineMeanGainVsDR,BaselineAllFeasible);

FairBaseline = ["example-wedge"; "under-spaced-diagnostic"; "random-layout-median"];
FairWorstRMSE = [max(exampleBaseline.rmse); max(compactBaseline.rmse); max(randomBaseline.rmseMedian)];
FairP90RMSE = [local_quantile(exampleBaseline.rmse(:),0.9); ...
               local_quantile(compactBaseline.rmse(:),0.9); ...
               local_quantile(randomBaseline.rmseMedian(:),0.9)];
FairAllFeasible = [all(exampleBaseline.feasible); all(compactBaseline.feasible); all(randomBaseline.feasibleMedian)];
TblFairBaseline = table(FairBaseline,FairWorstRMSE,FairP90RMSE,FairAllFeasible);

OUT.cfg = cfg;
OUT.gnss = gnss;
OUT.robust = robust;
OUT.candidates = cand;
OUT.deadReckoning = dr;
OUT.deadRmse = deadRmse;
OUT.singleRmse = singleRmse;
OUT.singleFeasible = singleFeasible;
OUT.exampleBaseline = exampleBaseline;
OUT.compactBaseline = compactBaseline;
OUT.randomBaseline = randomBaseline;
OUT.familyRmse = familyRmse;
OUT.familyTable = TblFamily;
OUT.baselineTable = TblBaseline;
OUT.fairBaselineTable = TblFairBaseline;

assignin('base','paper_baseline_ablation_out',OUT);
assignin('base','paper_baseline_family_table',TblFamily);
assignin('base','paper_baseline_table',TblBaseline);
assignin('base','paper_fair_baseline_table',TblFairBaseline);

disp('===== Paper baseline table =====');
disp(TblBaseline);
disp('===== Paper family comparison table =====');
disp(TblFamily);
disp('===== Paper fair baseline table =====');
disp(TblFairBaseline);

new_paper_figure('Paper_sanity_baseline_RMSE_log', [100 100 900 620]);
hold on;

plot(gnss, deadRmse, 'k--', 'LineWidth', 2.0, ...
    'DisplayName','dead-reckoning');
plot(gnss, singleRmse, 'Color',[0.45 0.45 0.45], ...
    'LineStyle','-.', 'Marker','s', 'LineWidth', 2.0, ...
    'DisplayName','single-USV');

for i = 1:nC
    st = family_style(char(cand{i}.family));
    plot(gnss, cand{i}.rmseVec, '-o', ...
        'Color', st.color, ...
        'MarkerFaceColor', st.color, ...
        'MarkerSize', 5.5, ...
        'LineWidth', 2.2, ...
        'DisplayName', sprintf('%s-best', st.name));
end

set(gca, 'YScale','log');
yline(cfg.requirement.rmse_xy, ':', 'Target RMSE', ...
    'Color',[0.25 0.25 0.25], 'LineWidth',1.4);
xlabel('\sigma_{GNSS} / m');
ylabel('Horizontal RMSE lower bound / m (log scale)');
title('Sanity baselines: weak baselines separated on log scale');
legend('Location','northwest');
apply_axis_style(gca);

new_paper_figure('Paper_fair_baseline_RMSE', [130 130 900 620]);
hold on;

plot(gnss, exampleBaseline.rmse, '--s', ...
    'Color',[0.45 0.45 0.45], ...
    'MarkerFaceColor',[0.45 0.45 0.45], ...
    'LineWidth', 1.8, ...
    'DisplayName','unoptimized example wedge');

plot(gnss, randomBaseline.rmseMedian, '--^', ...
    'Color',[0.55 0.35 0.62], ...
    'MarkerFaceColor',[0.55 0.35 0.62], ...
    'LineWidth', 1.8, ...
    'DisplayName','random layout median');

fill([gnss(:); flipud(gnss(:))], ...
     [randomBaseline.rmseQ25(:); flipud(randomBaseline.rmseQ75(:))], ...
     lighten_color(pal.purple, 0.45), ...
     'FaceAlpha',0.22, ...
     'EdgeColor','none', ...
     'HandleVisibility','off');

for i = 1:nC
    st = family_style(char(cand{i}.family));
    plot(gnss, cand{i}.rmseVec, '-o', ...
        'Color', st.color, ...
        'MarkerFaceColor', st.color, ...
        'MarkerSize', 5.5, ...
        'LineWidth', 2.2, ...
        'DisplayName', sprintf('%s-best', st.name));
end

xlabel('\sigma_{GNSS} / m');
ylabel('Horizontal RMSE lower bound / m');
title('Fair baseline comparison with comparable cooperative resources');
ylim([0, max([exampleBaseline.rmse(:); randomBaseline.rmseQ75(:); familyRmse(:); cfg.requirement.rmse_xy])*1.16]);
plot_target_band(gca, cfg.requirement.rmse_xy, 'Label','Target RMSE');
local_annotate_lowest_family(gnss, cand);
legend('Location','northwest');
apply_axis_style(gca);

new_paper_figure('Paper_fair_baseline_relative', [160 160 900 620]);
hold on;

ref = exampleBaseline.rmse(:);
plot(gnss, zeros(size(gnss)), '--s', ...
    'Color',[0.45 0.45 0.45], ...
    'MarkerFaceColor',[0.45 0.45 0.45], ...
    'LineWidth', 1.8, ...
    'DisplayName','example wedge reference');

plot(gnss, 100 * (ref - randomBaseline.rmseMedian(:)) ./ ref, '--^', ...
    'Color',[0.55 0.35 0.62], ...
    'MarkerFaceColor',[0.55 0.35 0.62], ...
    'LineWidth', 1.8, ...
    'DisplayName','random layout median');

for i = 1:nC
    st = family_style(char(cand{i}.family));
    gainPct = 100 * (ref - cand{i}.rmseVec(:)) ./ ref;
    plot(gnss, gainPct, '-o', ...
        'Color', st.color, ...
        'MarkerFaceColor', st.color, ...
        'MarkerSize', 5.5, ...
        'LineWidth', 2.2, ...
        'DisplayName', sprintf('%s-best', st.name));
end

xlabel('\sigma_{GNSS} / m');
ylabel('RMSE reduction vs example wedge / %');
title('Relative improvement against a meaningful cooperative baseline');
yline(0, ':', 'reference', 'Color',[0.30 0.30 0.30], 'HandleVisibility','off');
legend('Location','best');
apply_axis_style(gca);

end

function local_annotate_lowest_family(gnss, cand)
bestVal = inf;
bestX = gnss(1);
bestLabel = "";
bestColor = [0.1 0.1 0.1];

for i = 1:numel(cand)
    [v, idx] = min(cand{i}.rmseVec);
    if v < bestVal
        bestVal = v;
        bestX = gnss(idx);
        st = family_style(char(cand{i}.family));
        bestLabel = string(st.name) + " best";
        bestColor = st.color;
    end
end

annotate_best_point(gca, bestX, bestVal, bestLabel, bestColor);
end

function curve = local_eval_family_curve(fam, N, s, beta, fReq, gnss, cfg)
curve.rmse = nan(size(gnss));
curve.feasible = false(size(gnss));
curve.f_eff = nan(size(gnss));

for k = 1:numel(gnss)
    recProbe = evaluate_design(fam, N, s, beta, fReq, gnss(k), cfg, ...
        'StoreSeries', false);
    fEff = min(fReq, 0.95 * recProbe.f_phys_max);
    rec = evaluate_design(fam, N, s, beta, fEff, gnss(k), cfg, ...
        'StoreSeries', false);
    curve.rmse(k) = rec.rmse_xy;
    curve.feasible(k) = rec.is_feasible;
    curve.f_eff(k) = fEff;
end

curve.family = string(fam);
curve.N = N;
curve.s = s;
curve.beta_deg = beta;
curve.f_req = fReq;
end

function curve = local_eval_random_layout_curve(N, footprint, fReq, gnss, cfg, nLayout)
rng(cfg.seed + 701);
rm = nan(nLayout, numel(gnss));
feas = false(nLayout, numel(gnss));

for r = 1:nLayout
    A = local_random_layout(N, footprint);
    fPhys = acoustic_physical_limit(A, cfg);
    fEff = min(fReq, 0.95 * fPhys);

    for k = 1:numel(gnss)
        rec = local_eval_custom_anchors(A, fEff, gnss(k), cfg);
        rm(r,k) = rec.rmse_xy;
        feas(r,k) = rec.is_feasible;
    end
end

curve.rmseAll = rm;
curve.rmseMedian = local_quantile_rows(rm, 0.50);
curve.rmseQ25 = local_quantile_rows(rm, 0.25);
curve.rmseQ75 = local_quantile_rows(rm, 0.75);
curve.feasibleMedian = mean(feas,1) >= 0.5;
curve.N = N;
curve.footprint = footprint;
curve.f_req = fReq;
end

function A = local_random_layout(N, footprint)
theta = sort(2*pi*rand(N,1));
rad = 0.20 + 0.80 * sqrt(rand(N,1));
A = [rad .* cos(theta), rad .* sin(theta)];
A = A - mean(A,1);
curFoot = local_footprint(A);
if curFoot > 1e-9
    A = A / curFoot * footprint;
end
end

function rec = local_eval_custom_anchors(A, f_ac, sigma_gnss, cfg)
cfgEval = cfg;
cfgEval.num.store_pseries = false;
out = bcrlb_dynamic(A, f_ac, sigma_gnss, cfgEval);
met = metrics_from_P(out.Pxy);

rec = struct();
rec.rmse_xy = met.rmse_xy;
rec.area95 = met.area95;
rec.is_feasible = out.is_feasible;
rec.f_phys_max = out.f_phys_max;
end

function foot = local_footprint(A)
foot = 0;
for i = 1:size(A,1)
    for j = i+1:size(A,1)
        foot = max(foot, norm(A(i,:) - A(j,:)));
    end
end
end

function q = local_quantile_rows(X, alpha)
q = nan(1, size(X,2));
for k = 1:size(X,2)
    q(k) = local_quantile(X(:,k), alpha);
end
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
    w = pos - lo;
    q = (1-w)*x(lo) + w*x(hi);
end
end
