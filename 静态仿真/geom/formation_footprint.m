function foot = formation_footprint(anchors)
%FORMATION_FOOTPRINT Maximum pairwise horizontal anchor distance.

foot = 0;
for i = 1:size(anchors,1)
    for j = i+1:size(anchors,1)
        foot = max(foot, norm(anchors(i,:) - anchors(j,:)));
    end
end

end
