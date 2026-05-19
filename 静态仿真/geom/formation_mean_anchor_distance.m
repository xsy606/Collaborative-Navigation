function dbar = formation_mean_anchor_distance(anchors, p)
%FORMATION_MEAN_ANCHOR_DISTANCE Mean horizontal distance from p to anchors.

if nargin < 2 || isempty(p)
    p = [0; 0];
end

p = p(:).';
d = anchors - p;
dbar = mean(sqrt(sum(d.^2, 2)));

end
