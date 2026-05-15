function fmax = acoustic_physical_limit(anchors, cfg)
%ACOUSTIC_PHYSICAL_LIMIT Compute physical upper bound of acoustic update rate.
%
% T_cycle = sum_i (2*r_i/c + t_packet + t_guard) + t_sync
% fmax = 1 / T_cycle

p = cfg.target.nominal_state(1:2);
z = cfg.target.z;

N = size(anchors, 1);
Tcycle = cfg.acoustic.t_sync;

for i = 1:N
    dx = p(1) - anchors(i,1);
    dy = p(2) - anchors(i,2);
    r = sqrt(dx^2 + dy^2 + z^2);

    Tcycle = Tcycle + 2*r/cfg.acoustic.c + ...
        cfg.acoustic.t_packet + cfg.acoustic.t_guard;
end

fmax = 1 / Tcycle;

end