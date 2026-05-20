function anchors = build_formation_with_footprint(family, N, footprint, param)
%BUILD_FORMATION_WITH_FOOTPRINT Generate a formation with fixed footprint.

if nargin < 4
    param = struct();
end

anchors = build_formation(family, N, 1, param);
anchors = scale_formation_to_footprint(anchors, footprint);

end
