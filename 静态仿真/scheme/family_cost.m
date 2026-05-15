function [c, bd] = family_cost(family, anchors, N, f_ac, cfg)
%FAMILY_COST Engineering cost proxy with cost breakdown.
%
% Total cost:
%   C = familyPenalty * (C_ship + C_foot + C_rate + C_excess)
%
% Keep the footprint penalty additive. Multiplying all cost terms by a
% footprint scale over-penalizes large line/wedge layouts and makes the
% cost gap difficult to interpret.

family = lower(char(string(family)));

foot = local_footprint(anchors);

if isfield(cfg.cost.familyPenalty, family)
    familyPenalty = cfg.cost.familyPenalty.(family);
else
    familyPenalty = 1.0;
end

% Optional nonlinear footprint penalty.
if isfield(cfg.cost, 'foot_soft')
    footSoft = cfg.cost.foot_soft;
else
    footSoft = 500;
end

if isfield(cfg.cost, 'foot_hard')
    footHard = cfg.cost.foot_hard;
else
    footHard = 900;
end

if isfield(cfg.cost, 'foot_gamma')
    footGamma = cfg.cost.foot_gamma;
else
    footGamma = 1.5;
end

if isfield(cfg.cost, 'wFootExcess')
    wFootExcess = cfg.cost.wFootExcess;
else
    wFootExcess = footGamma;
end

den = max(footHard - footSoft, 1e-9);
excess = max(0, (foot - footSoft) / den);
footScale = 1 + footGamma * excess^2;

c_ship_raw = cfg.cost.wN * N;
c_foot_raw = cfg.cost.wFoot * foot / 100;
c_rate_raw = cfg.cost.wRate * f_ac;
c_excess_raw = wFootExcess * excess^2;

mult = familyPenalty;

bd = struct();
bd.familyPenalty = familyPenalty;
bd.footprintScale = footScale;
bd.footprint = foot;
bd.footprintExcess = excess;

bd.c_ship = mult * c_ship_raw;
bd.c_foot = mult * c_foot_raw;
bd.c_rate = mult * c_rate_raw;
bd.c_foot_excess = mult * c_excess_raw;

bd.raw_ship = c_ship_raw;
bd.raw_foot = c_foot_raw;
bd.raw_rate = c_rate_raw;
bd.raw_foot_excess = c_excess_raw;

c = bd.c_ship + bd.c_foot + bd.c_rate + bd.c_foot_excess;
bd.total = c;

end

function foot = local_footprint(A)
n = size(A,1);
foot = 0;

for i = 1:n
    for j = i+1:n
        foot = max(foot, norm(A(i,:) - A(j,:)));
    end
end
end
