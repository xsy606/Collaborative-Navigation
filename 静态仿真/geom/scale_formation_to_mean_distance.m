function anchorsScaled = scale_formation_to_mean_distance(anchors, p, targetMeanDistance)
%SCALE_FORMATION_TO_MEAN_DISTANCE Match mean anchor distance to a target.

if nargin < 2 || isempty(p)
    p = [0; 0];
end

p = p(:);
base = anchors - mean(anchors,1);
minMean = norm(p);

if targetMeanDistance <= minMean + 1e-9
    anchorsScaled = zeros(size(base));
    return;
end

lo = 0;
hi = 1;
while formation_mean_anchor_distance(base * hi, p) < targetMeanDistance
    hi = hi * 2;
    if hi > 1e6
        error('Could not scale formation to target mean distance %.3f.', targetMeanDistance);
    end
end

for k = 1:80
    mid = 0.5 * (lo + hi);
    if formation_mean_anchor_distance(base * mid, p) < targetMeanDistance
        lo = mid;
    else
        hi = mid;
    end
end

anchorsScaled = base * hi;

end
