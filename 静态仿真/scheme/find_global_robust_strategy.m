function robust = find_global_robust_strategy(cfg, gnss_grid)
%FIND_GLOBAL_ROBUST_STRATEGY Choose the best robust strategy among families.

if nargin < 2 || isempty(gnss_grid)
    gnss_grid = cfg.grid.gnss;
end

families = {'line','wedge','polygon'};
cand = cell(size(families));
rawCost = nan(size(families));

for i = 1:numel(families)
    cand{i} = find_family_best_fixed(families{i}, cfg, gnss_grid);
    cand{i}.family = string(families{i});
    rawCost(i) = cand{i}.cost;
end

cmin = min(rawCost);
cmax = max(rawCost);

if abs(cmax - cmin) < 1e-12
    costNorm = zeros(size(rawCost));
else
    costNorm = (rawCost - cmin) ./ (cmax - cmin);
end

for i = 1:numel(cand)
    r = cand{i}.rmseVec(:) / cfg.requirement.rmse_xy;

    cand{i}.p90_norm_rmse = local_quantile(r, 0.9);
    cand{i}.worst_norm_rmse = max(r);
    cand{i}.mean_norm_rmse = mean(r);
    cand{i}.cost_norm = costNorm(i);

    cand{i}.score = 0.60*cand{i}.p90_norm_rmse + ...
                    0.25*cand{i}.worst_norm_rmse + ...
                    0.15*cand{i}.cost_norm;

    if ~cand{i}.is_feasible_all
        cand{i}.score = cand{i}.score + 10;
    end
end

scores = cellfun(@(x) x.score, cand);
[~, idx] = min(scores);

robust = cand{idx};
robust.allFamilies = cand;
robust.gnss_grid = gnss_grid;

end

function q = local_quantile(x, alpha)
x = sort(x(:));
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