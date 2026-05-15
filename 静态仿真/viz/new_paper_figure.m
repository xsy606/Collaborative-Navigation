function fig = new_paper_figure(figName, figSize)
%NEW_PAPER_FIGURE Create a named paper-quality figure window.
%
% figSize example:
%   [100 100 760 560]

if nargin < 2 || isempty(figSize)
    figSize = [100 100 760 560];
end

fig = figure( ...
    'Color', 'w', ...
    'Name', figName, ...
    'NumberTitle', 'off', ...
    'Position', figSize);

end
