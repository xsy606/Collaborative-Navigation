function cfg = default_config(mode)
%DEFAULT_CONFIG  Unified configuration for USV-AUV cooperative localization.

if nargin < 1 || isempty(mode)
    if isappdata(0, 'USV_AUV_CoopNav_run_mode')
        mode = getappdata(0, 'USV_AUV_CoopNav_run_mode');
    else
        mode = 'tune';
    end
end

cfg = struct();

%% ---------------- Running mode ----------------
% tune: faster, coarse grids
% paper: denser grids, better for final figures
cfg.run.mode = char(string(mode));

%% ---------------- Random seed ----------------
cfg.seed = 2026;

%% ---------------- Target / AUV settings ----------------
cfg.target.dt = 0.2;                 % simulation time step / s
cfg.target.horizon = 180;            % horizon / s
cfg.target.z = 50;                   % AUV depth / m

% nominal state [x; y; vx; vy]
cfg.target.nominal_state = [300; 120; 0.6; 0.2];

%% ---------------- Prior ----------------
cfg.prior.sigma_pos = 8.0;           % m
cfg.prior.sigma_vel = 0.5;           % m/s

%% ---------------- Motion process noise ----------------
cfg.process.sigma_acc = 0.02;        % m/s^2

%% ---------------- Measurement noise ----------------
cfg.meas.sigma_range = 2.0;          % acoustic range noise / m
cfg.meas.rtk_sigma = 0.05;           % RTK-like anchor sigma / m
cfg.meas.gnss_sigma_default = 4.0;   % degraded GNSS sigma / m

%% ---------------- Acoustic physical parameters ----------------
cfg.acoustic.c = 1500;               % sound speed / m/s
cfg.acoustic.t_packet = 0.08;        % packet duration / s
cfg.acoustic.t_guard = 0.08;         % guard time / s
cfg.acoustic.t_sync = 0.15;          % synchronization overhead / s

%% ---------------- Example design ----------------
cfg.example.N = 5;
cfg.example.s = 150;
cfg.example.beta_deg = 80;
cfg.example.f = 0.6;

%% ---------------- Performance requirement ----------------
cfg.requirement.rmse_xy = 3.0;       % target horizontal RMSE / m

%% ---------------- Cost model ----------------
cfg.cost.wN = 1.0;
cfg.cost.wFoot = 0.18;
cfg.cost.wRate = 1.5;
cfg.cost.wFootExcess = 2.0;

cfg.cost.familyPenalty.line = 1.00;
cfg.cost.familyPenalty.wedge = 1.08;
cfg.cost.familyPenalty.polygon = 1.15;

cfg.cost.foot_soft = 500;    % m, footprint below this has no extra penalty
cfg.cost.foot_hard = 900;    % m, footprint above this becomes expensive
cfg.cost.foot_gamma = 2.0;   % legacy default for excess footprint penalty

%% ---------------- Numerical settings ----------------
cfg.num.min_sigma_anchor = 1e-4;
cfg.num.jitter = 1e-10;

%% ---------------- Monte Carlo ----------------
cfg.mc.Nrun = 50;
cfg.mc.truth_sigma_pos0 = 2.0;
cfg.mc.truth_sigma_vel0 = 0.1;

%% ---------------- Grids ----------------
switch lower(cfg.run.mode)
    case 'tune'
        cfg.grid.gnss = 0:1:5;
        cfg.grid.s = 50:100:450;
        cfg.grid.N = 3:5;
        cfg.grid.beta_deg = 45:30:135;
        cfg.acoustic.f_grid = 0.2:0.2:1.6;
        cfg.mc.Nrun = 40;

    case 'paper'
        cfg.grid.gnss = 0:0.5:6;
        cfg.grid.s = 50:50:500;
        cfg.grid.N = 3:6;
        cfg.grid.beta_deg = 30:15:150;
        cfg.acoustic.f_grid = 0.2:0.1:1.8;
        cfg.mc.Nrun = 150;

    otherwise
        error('Unknown run mode: %s', cfg.run.mode);
end

%% ---------------- Scheme 1 multi-scenario setting ----------------
cfg.scheme1.angle_offsets_deg = [-40, -20, 0, 20, 40];
cfg.scheme1.keep_nominal_velocity = true;
cfg.scheme1.best_score_worst = 0.75;
cfg.scheme1.best_score_cost = 0.25;

end
