function rec = evaluate_design(family, N, s, beta_deg, f_ac, sigma_gnss, cfg, varargin)
%EVALUATE_DESIGN Evaluate one formation design.

family = lower(char(string(family)));
storeSeries = true;

for iArg = 1:2:numel(varargin)
    name = lower(char(string(varargin{iArg})));
    switch name
        case 'storeseries'
            storeSeries = logical(varargin{iArg + 1});
        otherwise
            error('Unknown evaluate_design option: %s', name);
    end
end

param = struct();

if strcmpi(family, 'wedge')
    param.beta_deg = beta_deg;
elseif strcmpi(family, 'polygon')
    param.rot_deg = 180 / N;
end

anchors = build_formation(family, N, s, param);

cfgEval = cfg;
cfgEval.num.store_pseries = storeSeries;
out = bcrlb_dynamic(anchors, f_ac, sigma_gnss, cfgEval);
met = metrics_from_P(out.Pxy);

rec = struct();
rec.family = string(family);
rec.N = N;
rec.s = s;
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

rec.cost = family_cost(family, anchors, N, f_ac, cfg);

end
