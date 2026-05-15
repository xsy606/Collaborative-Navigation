function results = run_smoke_tests()
%RUN_SMOKE_TESTS Lightweight regression checks for the static project.

addpath(genpath(fileparts(fileparts(mfilename('fullpath')))));

results = struct();
results.passed = true;
results.messages = strings(0,1);

cfg = default_config('tune');

try
    A = build_formation('wedge', 5, 150, struct('beta_deg',80));
    local_assert(isequal(size(A), [5 2]), 'wedge formation size mismatch');
    local_assert(norm(mean(A,1)) < 1e-9, 'formation is not centered');

    fmax = acoustic_physical_limit(A, cfg);
    local_assert(isfinite(fmax) && fmax > 0, 'invalid acoustic fmax');

    met = metrics_from_P(eye(2));
    local_assert(abs(met.rmse_xy - sqrt(2)) < 1e-10, 'metrics_from_P RMSE failed');

    rec = evaluate_design('wedge', 5, 150, 80, 0.2, cfg.meas.gnss_sigma_default, cfg);
    local_assert(isfinite(rec.rmse_xy) && rec.rmse_xy > 0, 'evaluate_design invalid RMSE');
    local_assert(isfield(rec, 'cost') && isfinite(rec.cost), 'evaluate_design missing cost');

    [c, bd] = family_cost('line', A, 5, 0.2, cfg);
    cSum = bd.c_ship + bd.c_foot + bd.c_rate + bd.c_foot_excess;
    local_assert(abs(c - cSum) < 1e-10, 'family_cost breakdown does not sum to total');

    dr = dead_reckoning_bound(cfg);
    local_assert(dr.rmse_xy > rec.rmse_xy, 'dead-reckoning baseline should be worse than cooperative example');
catch ME
    results.passed = false;
    results.messages(end+1) = string(ME.message);
end

if results.passed
    disp('Static smoke tests passed.');
else
    disp('Static smoke tests failed.');
    disp(results.messages);
end

end

function local_assert(cond, msg)
if ~cond
    error('%s', msg);
end
end
