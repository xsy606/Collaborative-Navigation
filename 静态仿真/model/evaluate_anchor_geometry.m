function rec = evaluate_anchor_geometry(family, anchors, beta_deg, f_ac, sigma_gnss, cfg, varargin)
%EVALUATE_ANCHOR_GEOMETRY Evaluate a custom anchor geometry.

family = lower(char(string(family)));
storeSeries = true;

for iArg = 1:2:numel(varargin)
    name = lower(char(string(varargin{iArg})));
    switch name
        case 'storeseries'
            storeSeries = logical(varargin{iArg + 1});
        otherwise
            error('Unknown evaluate_anchor_geometry option: %s', name);
    end
end

cfgEval = cfg;
cfgEval.num.store_pseries = storeSeries;

out = bcrlb_dynamic(anchors, f_ac, sigma_gnss, cfgEval);
met = metrics_from_P(out.Pxy);

rec = struct();
rec.family = string(family);
rec.N = size(anchors, 1);
rec.s = nan;
rec.beta_deg = beta_deg;
rec.f_ac = f_ac;
rec.sigma_gnss = sigma_gnss;
rec.anchors = anchors;
rec.Pxy = out.Pxy;
rec.Pseries = out.Pseries;
rec.rmse_xy = met.rmse_xy;
rec.major95 = met.major95;
rec.minor95 = met.minor95;
rec.area95 = met.area95;
rec.condnum = met.condnum;
rec.f_phys_max = out.f_phys_max;
rec.is_feasible = out.is_feasible;
rec.cost = family_cost(family, anchors, rec.N, f_ac, cfg);
rec.footprint = formation_footprint(anchors);
rec.mean_anchor_distance = formation_mean_anchor_distance(anchors, cfg.target.nominal_state(1:2));

end
