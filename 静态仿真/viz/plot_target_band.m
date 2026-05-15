function h = plot_target_band(ax, yTarget, varargin)
%PLOT_TARGET_BAND Shade the acceptable region below a target line.

p = inputParser;
addParameter(p, 'Label', 'target', @(x) ischar(x) || isstring(x));
addParameter(p, 'Color', [0.78 0.88 0.80], @(x) isnumeric(x) && numel(x)==3);
addParameter(p, 'Alpha', 0.18, @(x) isnumeric(x) && isscalar(x));
parse(p, varargin{:});

if nargin < 1 || isempty(ax)
    ax = gca;
end

holdState = ishold(ax);
hold(ax, 'on');
xl = xlim(ax);
yl = ylim(ax);
y0 = yl(1);

if strcmpi(ax.YScale, 'log')
    h = yline(ax, yTarget, ':', char(string(p.Results.Label)), ...
        'Color', [0.25 0.25 0.25], 'LineWidth', 1.3);
    if ~holdState
        hold(ax, 'off');
    end
    return;
end

h = patch(ax, [xl(1) xl(2) xl(2) xl(1)], ...
    [y0 y0 yTarget yTarget], ...
    p.Results.Color, ...
    'FaceAlpha', p.Results.Alpha, ...
    'EdgeColor', 'none', ...
    'HandleVisibility', 'off');

try
    uistack(h, 'bottom');
catch
end

yline(ax, yTarget, ':', char(string(p.Results.Label)), ...
    'Color', [0.25 0.25 0.25], 'LineWidth', 1.3, ...
    'HandleVisibility','off');

xlim(ax, xl);
ylim(ax, yl);
if ~holdState
    hold(ax, 'off');
end

end
