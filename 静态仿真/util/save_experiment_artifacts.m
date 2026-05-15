function saved = save_experiment_artifacts(outRoot, cfg, result, varargin)
%SAVE_EXPERIMENT_ARTIFACTS Save reproducible experiment artifacts.
%
% saved = save_experiment_artifacts(outRoot, cfg, result, ...
%     'Name','paper_run', 'Tables', struct('summary', Tbl));

p = inputParser;
addParameter(p, 'Name', 'experiment', @(x) ischar(x) || isstring(x));
addParameter(p, 'Tables', struct(), @isstruct);
addParameter(p, 'SaveFigures', true, @(x) islogical(x) || isnumeric(x));
parse(p, varargin{:});

name = char(string(p.Results.Name));
tables = p.Results.Tables;

if ~exist(outRoot, 'dir')
    mkdir(outRoot);
end

figDir = fullfile(outRoot, 'figures');
tableDir = fullfile(outRoot, 'tables');
if ~exist(figDir, 'dir'), mkdir(figDir); end
if ~exist(tableDir, 'dir'), mkdir(tableDir); end

saved = struct();
saved.outputRoot = outRoot;
saved.configPath = fullfile(outRoot, 'config_snapshot.mat');
saved.resultPath = fullfile(outRoot, sprintf('%s_result.mat', name));
saved.runInfoPath = fullfile(outRoot, 'run_info.txt');

save(saved.configPath, 'cfg');
save(saved.resultPath, 'result', '-v7.3');

tableNames = fieldnames(tables);
saved.tables = strings(numel(tableNames),1);
for i = 1:numel(tableNames)
    tbl = tables.(tableNames{i});
    if istable(tbl)
        path = fullfile(tableDir, tableNames{i} + ".csv");
        writetable(tbl, path);
        saved.tables(i) = string(path);
    end
end

if p.Results.SaveFigures
    saved.figures = save_all_open_figures(figDir, '');
else
    saved.figures = strings(0,2);
end

local_write_run_info(saved.runInfoPath, name, cfg, saved);

end

function local_write_run_info(path, name, cfg, saved)
fid = fopen(path, 'w');
if fid < 0
    warning('Could not write run info: %s', path);
    return;
end

cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'Experiment: %s\n', name);
fprintf(fid, 'Generated: %s\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
fprintf(fid, 'MATLAB: %s\n', version);
fprintf(fid, 'Working directory: %s\n', pwd);

if isfield(cfg, 'seed')
    fprintf(fid, 'Seed: %g\n', cfg.seed);
end
if isfield(cfg, 'run') && isfield(cfg.run, 'mode')
    fprintf(fid, 'Run mode: %s\n', cfg.run.mode);
end

fprintf(fid, '\nSaved artifacts:\n');
fprintf(fid, '  config: %s\n', saved.configPath);
fprintf(fid, '  result: %s\n', saved.resultPath);
fprintf(fid, '  figures: %s\n', fullfile(saved.outputRoot, 'figures'));
fprintf(fid, '  tables: %s\n', fullfile(saved.outputRoot, 'tables'));
end
