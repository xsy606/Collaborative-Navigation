function out = bcrlb_dynamic(anchors, f_ac, sigma_gnss, cfg)
%BCRLB_DYNAMIC Dynamic BCRLB recursion with event-time acoustic updates.

dt = cfg.target.dt;
T = cfg.target.horizon;
K = round(T / dt);
storeSeries = true;
if isfield(cfg, 'num') && isfield(cfg.num, 'store_pseries')
    storeSeries = logical(cfg.num.store_pseries);
end

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

xNom = cfg.target.nominal_state;

if storeSeries
    Pseries = zeros(4,4,K);
    updateMask = false(K,1);
else
    Pseries = [];
    updateMask = [];
end

fphys = acoustic_physical_limit(anchors, cfg);
isFeasible = f_ac <= fphys + 1e-12;

if f_ac <= 0
    updateTimes = [];
else
    updateTimes = (1/f_ac):(1/f_ac):T;
end

iUpd = 1;

for k = 1:K
    tk = k * dt;

    % Predict
    xNom = F * xNom;
    P = F * P * F.' + Q;
    P = 0.5 * (P + P.');

    % Event-time acoustic update
    if iUpd <= numel(updateTimes) && tk + 1e-12 >= updateTimes(iUpd)
        [Jxy, ~] = range_snapshot_info_schur(xNom(1:2), anchors, sigma_gnss, cfg);

        Jmeas = zeros(4,4);
        Jmeas(1:2,1:2) = Jxy;

        Jpred = pinv(P);
        Jpost = Jpred + Jmeas;
        P = pinv(Jpost);
        P = 0.5 * (P + P.');

        if storeSeries
            updateMask(k) = true;
        end
        iUpd = iUpd + 1;
    end

    if storeSeries
        Pseries(:,:,k) = P;
    end
end

out.P = P;
out.Pxy = P(1:2,1:2);
out.Pseries = Pseries;
out.updateMask = updateMask;
out.f_phys_max = fphys;
out.is_feasible = isFeasible;

end
