function [Jxy, dbg] = range_snapshot_info_schur(p, anchors, sigma_gnss, cfg)
%RANGE_SNAPSHOT_INFO_SCHUR
% Build augmented Fisher information matrix for one range snapshot.
%
% Unknowns:
%   theta = [p_x, p_y, a1_x, a1_y, ..., aN_x, aN_y]^T
%
% Measurement:
%   r_i = sqrt((p_x-a_x)^2 + (p_y-a_y)^2 + z^2)
%
% Anchor prior:
%   a_i ~ N(a_i_nom, sigma_gnss^2 I)
%
% Effective target information:
%   J_eff = J_pp - J_pa * inv(J_aa) * J_ap

N = size(anchors, 1);
dim = 2 + 2*N;
J = zeros(dim, dim);

sigma_r = cfg.meas.sigma_range;
z = cfg.target.z;

for i = 1:N
    ai = anchors(i,:).';
    dx = p(1) - ai(1);
    dy = p(2) - ai(2);
    r = sqrt(dx^2 + dy^2 + z^2);

    gx = dx / r;
    gy = dy / r;
    g = [gx; gy];

    h = zeros(dim, 1);
    h(1:2) = g;

    idx = 2 + (2*i-1:2*i);
    h(idx) = -g;

    J = J + (h*h.') / sigma_r^2;
end

% Anchor prior information
sigA = max(sigma_gnss, cfg.num.min_sigma_anchor);
Ja_prior = (1 / sigA^2) * eye(2);

for i = 1:N
    idx = 2 + (2*i-1:2*i);
    J(idx, idx) = J(idx, idx) + Ja_prior;
end

J = 0.5 * (J + J.');

Jpp = J(1:2, 1:2);
Jpa = J(1:2, 3:end);
Jap = Jpa.';
Jaa = J(3:end, 3:end);

Jxy = Jpp - Jpa * (Jaa \ Jap);
Jxy = 0.5 * (Jxy + Jxy.');

% Numerical safety
Jxy = Jxy + cfg.num.jitter * eye(2);

dbg.J_aug = J;
dbg.Jpp = Jpp;
dbg.Jpa = Jpa;
dbg.Jaa = Jaa;
dbg.sigma_gnss_used = sigA;

end