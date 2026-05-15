function anchors = build_formation(family, N, s, param)
%BUILD_FORMATION Generate USV anchor coordinates for line / wedge / polygon.
%
% Added:
%   param.rot_deg : rotate the whole formation around its centroid.

if nargin < 4
    param = struct();
end

family = lower(char(string(family)));

if isfield(param, 'rot_deg')
    rot_deg = param.rot_deg;
else
    rot_deg = 0;
end

switch family
    case 'line'
        x = ((0:N-1) - (N-1)/2) * s;
        y = zeros(1, N);
        anchors = [x(:), y(:)];

    case 'polygon'
        if N < 3
            x = ((0:N-1) - (N-1)/2) * s;
            y = zeros(1, N);
            anchors = [x(:), y(:)];
        else
            R = s / (2 * sin(pi / N));
            theta = (0:N-1).' * 2*pi/N;
            anchors = [R*cos(theta), R*sin(theta)];
        end

    case 'wedge'
        if isfield(param, 'beta_deg')
            beta_deg = param.beta_deg;
        else
            beta_deg = 80;
        end

        if N == 1
            anchors = [0, 0];
        else
            beta = deg2rad(beta_deg);
            half = beta / 2;

            anchors = zeros(N, 2);
            anchors(1,:) = [0, 0];

            nLeft = floor((N-1)/2);
            nRight = (N-1) - nLeft;

            idx = 2;
            for k = 1:nLeft
                anchors(idx,:) = [k*s*cos(half), k*s*sin(half)];
                idx = idx + 1;
            end

            for k = 1:nRight
                anchors(idx,:) = [k*s*cos(half), -k*s*sin(half)];
                idx = idx + 1;
            end
        end

    otherwise
        error('Unknown formation family: %s', family);
end

% Center the formation.
anchors(:,1) = anchors(:,1) - mean(anchors(:,1));
anchors(:,2) = anchors(:,2) - mean(anchors(:,2));

% Rotate formation.
Rrot = [cosd(rot_deg), -sind(rot_deg);
        sind(rot_deg),  cosd(rot_deg)];

anchors = (Rrot * anchors.').';

end