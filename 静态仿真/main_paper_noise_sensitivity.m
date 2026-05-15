function OUT = main_paper_noise_sensitivity(mode)
%MAIN_PAPER_NOISE_SENSITIVITY Test conclusion stability under noise changes.
%
% The selected robust strategy is re-evaluated while perturbing acoustic
% range noise and target process noise around the default setting.

close all;
paper_style();
pal = paper_palette();
if nargin < 1
    cfg0 = default_config();
else
    cfg0 = default_config(mode);
end

gnssEval = cfg0.meas.gnss_sigma_default;
robust = find_global_robust_strategy(cfg0, cfg0.grid.gnss);

sigmaRangeGrid = [0.5 1 1.5 2 2.5 3 4];
sigmaAccGrid = [0.005 0.01 0.02 0.04 0.08];

rmseRange = nan(size(sigmaRangeGrid));
areaRange = nan(size(sigmaRangeGrid));
feasRange = false(size(sigmaRangeGrid));

for k = 1:numel(sigmaRangeGrid)
    cfg = cfg0;
    cfg.meas.sigma_range = sigmaRangeGrid(k);
    rec = evaluate_design(char(robust.family), robust.N, robust.s, ...
        robust.beta_deg, robust.f_ac, gnssEval, cfg, ...
        'StoreSeries', false);
    rmseRange(k) = rec.rmse_xy;
    areaRange(k) = rec.area95;
    feasRange(k) = rec.is_feasible;
end

rmseAcc = nan(size(sigmaAccGrid));
areaAcc = nan(size(sigmaAccGrid));
feasAcc = false(size(sigmaAccGrid));

for k = 1:numel(sigmaAccGrid)
    cfg = cfg0;
    cfg.process.sigma_acc = sigmaAccGrid(k);
    rec = evaluate_design(char(robust.family), robust.N, robust.s, ...
        robust.beta_deg, robust.f_ac, gnssEval, cfg, ...
        'StoreSeries', false);
    rmseAcc(k) = rec.rmse_xy;
    areaAcc(k) = rec.area95;
    feasAcc(k) = rec.is_feasible;
end

RangeNoise = sigmaRangeGrid(:);
RangeRMSE = rmseRange(:);
RangeArea95 = areaRange(:);
RangeRMSE_Relative = rmseRange(:) / local_interp_nominal(sigmaRangeGrid, rmseRange, cfg0.meas.sigma_range);
RangeArea95_Relative = areaRange(:) / local_interp_nominal(sigmaRangeGrid, areaRange, cfg0.meas.sigma_range);
RangeFeasible = feasRange(:);
TblRange = table(RangeNoise,RangeRMSE,RangeArea95, ...
    RangeRMSE_Relative,RangeArea95_Relative,RangeFeasible);

ProcessSigmaAcc = sigmaAccGrid(:);
ProcessRMSE = rmseAcc(:);
ProcessArea95 = areaAcc(:);
ProcessRMSE_Relative = rmseAcc(:) / local_interp_nominal(sigmaAccGrid, rmseAcc, cfg0.process.sigma_acc);
ProcessArea95_Relative = areaAcc(:) / local_interp_nominal(sigmaAccGrid, areaAcc, cfg0.process.sigma_acc);
ProcessFeasible = feasAcc(:);
TblProcess = table(ProcessSigmaAcc,ProcessRMSE,ProcessArea95, ...
    ProcessRMSE_Relative,ProcessArea95_Relative,ProcessFeasible);

OUT.cfg = cfg0;
OUT.robust = robust;
OUT.gnssEval = gnssEval;
OUT.sigmaRangeGrid = sigmaRangeGrid;
OUT.sigmaAccGrid = sigmaAccGrid;
OUT.rmseRange = rmseRange;
OUT.areaRange = areaRange;
OUT.feasRange = feasRange;
OUT.rmseAcc = rmseAcc;
OUT.areaAcc = areaAcc;
OUT.feasAcc = feasAcc;
OUT.rangeTable = TblRange;
OUT.processTable = TblProcess;

assignin('base','paper_noise_sensitivity_out',OUT);
assignin('base','paper_range_noise_table',TblRange);
assignin('base','paper_process_noise_table',TblProcess);

disp('===== Paper range-noise sensitivity table =====');
disp(TblRange);
disp('===== Paper process-noise sensitivity table =====');
disp(TblProcess);

new_paper_figure('Paper_noise_sensitivity_range', [100 100 840 600]);
yyaxis left;
plot(sigmaRangeGrid, rmseRange, '-o', ...
    'Color', pal.navy, ...
    'MarkerFaceColor', pal.navy, ...
    'LineWidth',2.2);
ylabel('Horizontal RMSE lower bound / m');
yline(cfg0.requirement.rmse_xy, ':', 'Target RMSE', ...
    'Color',[0.30 0.30 0.30], 'LineWidth',1.2);

yyaxis right;
plot(sigmaRangeGrid, areaRange, '-s', ...
    'Color', pal.orange, ...
    'MarkerFaceColor', pal.orange, ...
    'LineWidth',2.2);
ylabel('95% ellipse area / m^2');

xlabel('Acoustic range noise \sigma_r / m');
title(sprintf('Range-noise sensitivity of selected %s strategy', char(robust.family)));
apply_axis_style(gca);

new_paper_figure('Paper_noise_sensitivity_process', [130 130 840 600]);
yyaxis left;
plot(sigmaAccGrid, rmseAcc, '-o', ...
    'Color', pal.navy, ...
    'MarkerFaceColor', pal.navy, ...
    'LineWidth',2.2);
ylabel('Horizontal RMSE lower bound / m');
yline(cfg0.requirement.rmse_xy, ':', 'Target RMSE', ...
    'Color',[0.30 0.30 0.30], 'LineWidth',1.2);

yyaxis right;
plot(sigmaAccGrid, areaAcc, '-s', ...
    'Color', pal.orange, ...
    'MarkerFaceColor', pal.orange, ...
    'LineWidth',2.2);
ylabel('95% ellipse area / m^2');

xlabel('Process acceleration noise \sigma_a / m/s^2');
title(sprintf('Process-noise sensitivity of selected %s strategy', char(robust.family)));
apply_axis_style(gca);

new_paper_figure('Paper_noise_sensitivity_normalized', [160 160 980 460]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

nexttile; hold on; grid on; box on;
plot(sigmaRangeGrid, RangeRMSE_Relative, '-o', ...
    'Color', pal.navy, ...
    'MarkerFaceColor', pal.navy, ...
    'LineWidth',2.0, ...
    'DisplayName','RMSE / nominal');
plot(sigmaRangeGrid, RangeArea95_Relative, '-s', ...
    'Color', pal.orange, ...
    'MarkerFaceColor', pal.orange, ...
    'LineWidth',2.0, ...
    'DisplayName','Area95 / nominal');
xline(cfg0.meas.sigma_range, 'k--', 'nominal');
yline(1.0, ':', 'nominal level', 'Color',[0.35 0.35 0.35], ...
    'HandleVisibility','off');
xlabel('Acoustic range noise \sigma_r / m');
ylabel('Relative metric');
title('Range-noise sensitivity on common scale');
legend('Location','northwest');
apply_axis_style(gca);

nexttile; hold on; grid on; box on;
plot(sigmaAccGrid, ProcessRMSE_Relative, '-o', ...
    'Color', pal.navy, ...
    'MarkerFaceColor', pal.navy, ...
    'LineWidth',2.0, ...
    'DisplayName','RMSE / nominal');
plot(sigmaAccGrid, ProcessArea95_Relative, '-s', ...
    'Color', pal.orange, ...
    'MarkerFaceColor', pal.orange, ...
    'LineWidth',2.0, ...
    'DisplayName','Area95 / nominal');
xline(cfg0.process.sigma_acc, 'k--', 'nominal');
yline(1.0, ':', 'nominal level', 'Color',[0.35 0.35 0.35], ...
    'HandleVisibility','off');
xlabel('Process acceleration noise \sigma_a / m/s^2');
ylabel('Relative metric');
title('Process-noise sensitivity on common scale');
legend('Location','northwest');
apply_axis_style(gca);

end

function y0 = local_interp_nominal(x, y, x0)
[~, idx] = min(abs(x - x0));
y0 = y(idx);
if abs(x(idx)-x0) > 1e-12
    y0 = interp1(x, y, x0, 'linear', 'extrap');
end
y0 = max(y0, eps);
end
