function saved = save_all_open_figures(outDir, prefix)
%SAVE_ALL_OPEN_FIGURES Save all open MATLAB figures as PNG and FIG files.

if nargin < 2 || isempty(prefix)
    prefix = '';
end

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

figs = findall(groot, 'Type', 'figure');
figs = flipud(figs(:));
saved = strings(numel(figs), 2);

for i = 1:numel(figs)
    fig = figs(i);
    name = get(fig, 'Name');

    if isempty(name)
        name = sprintf('figure_%02d', i);
    end

    fileBase = local_safe_name(strcat(prefix, name));
    pngPath = fullfile(outDir, fileBase + ".png");
    figPath = fullfile(outDir, fileBase + ".fig");

    try
        exportgraphics(fig, pngPath, 'Resolution', 300);
    catch
        saveas(fig, pngPath);
    end

    savefig(fig, figPath);

    saved(i,1) = string(pngPath);
    saved(i,2) = string(figPath);
end

end

function name = local_safe_name(name)
name = char(string(name));
name = regexprep(name, '[^\w\-]+', '_');
name = regexprep(name, '_+', '_');
name = regexprep(name, '^_|_$', '');

if isempty(name)
    name = 'figure';
end
end
