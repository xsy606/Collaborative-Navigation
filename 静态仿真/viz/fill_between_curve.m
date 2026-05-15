function h = fill_between_curve(ax, x, yLow, yHigh, color, alphaVal, varargin)
%FILL_BETWEEN_CURVE Draw a translucent band between two curves.

if nargin < 6 || isempty(alphaVal)
    alphaVal = 0.16;
end

x = x(:);
yLow = yLow(:);
yHigh = yHigh(:);

h = fill(ax, [x; flipud(x)], [yLow; flipud(yHigh)], color, ...
    'FaceAlpha', alphaVal, ...
    'EdgeColor', 'none', ...
    varargin{:});

try
    uistack(h, 'bottom');
catch
end

end
