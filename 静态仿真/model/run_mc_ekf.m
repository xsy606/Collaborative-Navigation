function mc = run_mc_ekf(strategy, sigma_gnss, cfg)
%RUN_MC_EKF Monte Carlo EKF validation.

rng(cfg.seed);

Nrun = cfg.mc.Nrun;
dt = cfg.target.dt;
T = cfg.target.horizon;
K = round(T / dt);

anchors_nom = strategy.anchors;
N = size(anchors_nom,1);

q = cfg.process.sigma_acc^2;

F = [1 0 dt 0;
     0 1 0 dt;
     0 0 1  0;
     0 0 0  1];

G = [0.5*dt^2 0;
     0 0.5*dt^2;
     dt 0;
     0 dt];

Q = G * (q * eye(2)) * G.';

if strategy.f_ac <= 0
    updateTimes = [];
else
    updateTimes = (1/strategy.f_ac):(1/strategy.f_ac):T;
end

rmseAccum = zeros(K,1);
finalErr = zeros(Nrun,2);

for m = 1:Nrun
    Atrue = anchors_nom + sigma_gnss * randn(N,2);

    xTrue = cfg.target.nominal_state + ...
        [cfg.mc.truth_sigma_pos0 * randn(2,1); ...
         cfg.mc.truth_sigma_vel0 * randn(2,1)];

    xHat = cfg.target.nominal_state;

    P = diag([cfg.prior.sigma_pos^2, cfg.prior.sigma_pos^2, ...
              cfg.prior.sigma_vel^2, cfg.prior.sigma_vel^2]);

    iUpd = 1;

    for k = 1:K
        tk = k * dt;

        % Truth propagation
        w = cfg.process.sigma_acc * randn(2,1);
        xTrue = F * xTrue + G * w;

        % EKF prediction
        xHat = F * xHat;
        P = F * P * F.' + Q;
        P = 0.5 * (P + P.');

        % EKF update
        if iUpd <= numel(updateTimes) && tk + 1e-12 >= updateTimes(iUpd)
            z = zeros(N,1);

            for i = 1:N
                dx = xTrue(1) - Atrue(i,1);
                dy = xTrue(2) - Atrue(i,2);
                z(i) = sqrt(dx^2 + dy^2 + cfg.target.z^2) + ...
                    cfg.meas.sigma_range * randn;
            end

            [Reff, H, zhat] = local_range_model(xHat, anchors_nom, sigma_gnss, cfg);

            S = H * P * H.' + Reff;
            S = 0.5 * (S + S.');

            Kk = P * H.' / S;
            innov = z - zhat;

            xHat = xHat + Kk * innov;

            I = eye(4);
            P = (I - Kk*H) * P * (I - Kk*H).' + Kk * Reff * Kk.';
            P = 0.5 * (P + P.');

            iUpd = iUpd + 1;
        end

        e = xHat(1:2) - xTrue(1:2);
        rmseAccum(k) = rmseAccum(k) + e.' * e;
    end

    finalErr(m,:) = (xHat(1:2) - xTrue(1:2)).';
end

rmseTime = sqrt(rmseAccum / Nrun);
finalRMSE = sqrt(mean(sum(finalErr.^2,2)));
finalErrNorm = sqrt(sum(finalErr.^2,2));
[ciMean, ciRmse] = local_bootstrap_final_ci(finalErrNorm, cfg.seed + 99);

out = bcrlb_dynamic(anchors_nom, strategy.f_ac, sigma_gnss, cfg);
met = metrics_from_P(out.Pxy);

Kbound = size(out.Pseries,3);
boundTime = zeros(Kbound,1);

for k = 1:Kbound
    Pxy = out.Pseries(1:2,1:2,k);
    boundTime(k) = sqrt(max(trace(Pxy),0));
end

mc.rmse_time = rmseTime;
mc.final_rmse = finalRMSE;
mc.final_error_norm = finalErrNorm;
mc.final_error_mean = mean(finalErrNorm);
mc.final_error_std = std(finalErrNorm);
mc.final_error_mean_ci95 = ciMean;
mc.final_rmse_ci95 = ciRmse;
mc.final_err = finalErr;
mc.scatter = finalErr;

mc.bound_time = boundTime;
mc.bound_rmse = met.rmse_xy;
mc.bound_area95 = met.area95;
mc.Pxy_bound = out.Pxy;
mc.anchors = anchors_nom;

end

function [Reff, H, zhat] = local_range_model(xHat, anchors, sigma_gnss, cfg)
N = size(anchors,1);
H = zeros(N,4);
zhat = zeros(N,1);
Reff = zeros(N,N);

for i = 1:N
    dx = xHat(1) - anchors(i,1);
    dy = xHat(2) - anchors(i,2);
    r = sqrt(dx^2 + dy^2 + cfg.target.z^2);

    gx = dx / r;
    gy = dy / r;

    H(i,:) = [gx, gy, 0, 0];
    zhat(i) = r;

    var_anchor = sigma_gnss^2 * (gx^2 + gy^2);
    Reff(i,i) = cfg.meas.sigma_range^2 + var_anchor;
end

Reff = 0.5 * (Reff + Reff.');

end

function [ciMean, ciRmse] = local_bootstrap_final_ci(errNorm, seed)
errNorm = errNorm(:);
n = numel(errNorm);

if n < 2
    ciMean = [errNorm; errNorm].';
    ciRmse = [errNorm; errNorm].';
    return;
end

rng(seed);
B = 300;
meanBoot = zeros(B,1);
rmseBoot = zeros(B,1);

for b = 1:B
    idx = randi(n, n, 1);
    sample = errNorm(idx);
    meanBoot(b) = mean(sample);
    rmseBoot(b) = sqrt(mean(sample.^2));
end

ciMean = local_quantile_vec(meanBoot, [0.025 0.975]);
ciRmse = local_quantile_vec(rmseBoot, [0.025 0.975]);
end

function q = local_quantile_vec(x, alpha)
x = sort(x(:));
q = zeros(size(alpha));

for i = 1:numel(alpha)
    a = alpha(i);
    pos = 1 + (numel(x)-1)*a;
    lo = floor(pos);
    hi = ceil(pos);

    if lo == hi
        q(i) = x(lo);
    else
        w = pos - lo;
        q(i) = (1-w)*x(lo) + w*x(hi);
    end
end
end
