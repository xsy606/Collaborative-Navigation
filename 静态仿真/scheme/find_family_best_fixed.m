function best = find_family_best_fixed(family, cfg, gnss_grid)
%FIND_FAMILY_BEST_FIXED Find the best fixed strategy for one family.

family = lower(char(string(family)));

cand = {};
cost = [];
p90v = [];
worstv = [];
meanv = [];
feasAll = [];

for N = cfg.grid.N
    for s = cfg.grid.s
        betaSet = local_beta_set(family, cfg);

        for beta = betaSet
            for f = cfg.acoustic.f_grid
                rmseVec = nan(size(gnss_grid));
                feasibleVec = false(size(gnss_grid));
                rec0 = [];

                for k = 1:numel(gnss_grid)
                    rec = evaluate_design(family, N, s, beta, f, gnss_grid(k), cfg, ...
                        'StoreSeries', false);
                    rmseVec(k) = rec.rmse_xy;
                    feasibleVec(k) = rec.is_feasible;

                    if k == 1
                        rec0 = rec;
                    end
                end

                c = rec0;
                c.rmseVec = rmseVec;
                c.feasibleVec = feasibleVec;
                c.is_feasible_all = all(feasibleVec);

                cand{end+1} = c; %#ok<AGROW>
                cost(end+1) = c.cost; %#ok<AGROW>
                feasAll(end+1) = c.is_feasible_all; %#ok<AGROW>

                r = rmseVec(:) / cfg.requirement.rmse_xy;
                p90v(end+1) = local_quantile(r, 0.9); %#ok<AGROW>
                worstv(end+1) = max(r); %#ok<AGROW>
                meanv(end+1) = mean(r); %#ok<AGROW>
            end
        end
    end
end

if isempty(cand)
    best = struct();
    return;
end

idxNorm = find(feasAll > 0.5);
if isempty(idxNorm)
    idxNorm = 1:numel(cost);
end

cmin = min(cost(idxNorm));
cmax = max(cost(idxNorm));

if abs(cmax - cmin) < 1e-12
    costNorm = zeros(size(cost));
else
    costNorm = (cost - cmin) ./ (cmax - cmin);
end

score = 0.60*p90v + 0.25*worstv + 0.15*costNorm;

for i = 1:numel(cand)
    if ~cand{i}.is_feasible_all
        score(i) = score(i) + 10;
    end
end

[~, idx] = min(score);

best = cand{idx};
best.p90_norm_rmse = p90v(idx);
best.worst_norm_rmse = worstv(idx);
best.mean_norm_rmse = meanv(idx);
best.cost_norm = costNorm(idx);
best.score = score(idx);

end

function betaSet = local_beta_set(family, cfg)
if strcmpi(family, 'wedge')
    betaSet = cfg.grid.beta_deg;
else
    betaSet = cfg.example.beta_deg;
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
