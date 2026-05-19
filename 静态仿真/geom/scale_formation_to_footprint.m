function anchorsScaled = scale_formation_to_footprint(anchors, targetFootprint)
%SCALE_FORMATION_TO_FOOTPRINT Scale anchors to a target max pairwise distance.

foot = formation_footprint(anchors);
if foot <= eps
    anchorsScaled = anchors;
else
    anchorsScaled = anchors / foot * targetFootprint;
end

end
