function apply_axis_style(ax)
%APPLY_AXIS_STYLE Apply consistent axis style.

if nargin < 1 || isempty(ax)
    ax = gca;
end

grid(ax, 'on');
box(ax, 'on');
ax.LineWidth = 1.15;
ax.FontName = 'Times New Roman';
ax.FontSize = 12.5;
ax.GridAlpha = 0.12;
ax.MinorGridAlpha = 0.06;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
ax.TickDir = 'out';
ax.Layer = 'top';
ax.Color = [0.985 0.987 0.990];

end
