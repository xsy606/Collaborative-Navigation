function mask = pareto_front_mask(values, directions)
%PARETO_FRONT_MASK Return nondominated points.
%
% values     : n-by-m objective matrix.
% directions : 1-by-m string/cell array, each item is 'min' or 'max'.

if nargin < 2 || isempty(directions)
    directions = repmat("min", 1, size(values,2));
end

directions = string(directions);
V = values;

for j = 1:size(V,2)
    if strcmpi(directions(j), "max")
        V(:,j) = -V(:,j);
    elseif ~strcmpi(directions(j), "min")
        error('Unknown Pareto direction: %s', directions(j));
    end
end

n = size(V,1);
mask = true(n,1);

for i = 1:n
    if ~all(isfinite(V(i,:)))
        mask(i) = false;
        continue;
    end

    for j = 1:n
        if i == j || ~all(isfinite(V(j,:)))
            continue;
        end

        dominates = all(V(j,:) <= V(i,:)) && any(V(j,:) < V(i,:));
        if dominates
            mask(i) = false;
            break;
        end
    end
end

end
