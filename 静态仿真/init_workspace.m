function cfg = init_workspace(mode)
%INIT_WORKSPACE Initialize paths and default configuration for this project.
%
% Usage:
%   cfg = init_workspace();          % use default mode in cfg/default_config.m
%   cfg = init_workspace('paper');   % switch to paper-density grids
%   cfg = init_workspace('tune');    % switch to faster tuning grids

if nargin >= 1 && ~isempty(mode)
    setappdata(0, 'USV_AUV_CoopNav_run_mode', char(string(mode)));
else
    if isappdata(0, 'USV_AUV_CoopNav_run_mode')
        rmappdata(0, 'USV_AUV_CoopNav_run_mode');
    end
end

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(rootDir));

cfg = default_config();

assignin('base', 'cfg', cfg);
assignin('base', 'project_root', rootDir);

fprintf('USV_AUV_CoopNav workspace initialized.\n');
fprintf('Project root: %s\n', rootDir);
fprintf('Run mode: %s\n', cfg.run.mode);
fprintf('Example design: N=%d, s=%.1f m, beta=%.1f deg, f=%.2f Hz\n', ...
    cfg.example.N, cfg.example.s, cfg.example.beta_deg, cfg.example.f);
fprintf('Use main_run_all, main_fig*.m, or main_scheme*.m to run simulations.\n');

end
