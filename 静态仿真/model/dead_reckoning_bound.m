function out = dead_reckoning_bound(cfg)
%DEAD_RECKONING_BOUND Propagate the prior without acoustic measurements.
%
% This baseline is useful for quantifying the cooperative-navigation gain.

dt = cfg.target.dt;
T = cfg.target.horizon;
K = round(T / dt);

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

P = diag([cfg.prior.sigma_pos^2, cfg.prior.sigma_pos^2, ...
          cfg.prior.sigma_vel^2, cfg.prior.sigma_vel^2]);

Pseries = zeros(4,4,K);
rmseTime = zeros(K,1);

for k = 1:K
    P = F * P * F.' + Q;
    P = 0.5 * (P + P.');
    Pseries(:,:,k) = P;
    rmseTime(k) = sqrt(max(trace(P(1:2,1:2)), 0));
end

met = metrics_from_P(P(1:2,1:2));

out.P = P;
out.Pxy = P(1:2,1:2);
out.Pseries = Pseries;
out.rmse_time = rmseTime;
out.rmse_xy = met.rmse_xy;
out.major95 = met.major95;
out.minor95 = met.minor95;
out.area95 = met.area95;
out.condnum = met.condnum;

end
