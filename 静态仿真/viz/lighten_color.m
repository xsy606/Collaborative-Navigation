function c = lighten_color(color, amount)
%LIGHTEN_COLOR Blend a color toward white.

if nargin < 2
    amount = 0.5;
end

amount = max(0, min(1, amount));
c = color + (1 - color) * amount;

end
