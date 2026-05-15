function st = family_style(family)
%FAMILY_STYLE Return unified color, marker and line style for each family.

family = lower(char(string(family)));

switch family
    case 'line'
        st.color = [0.10 0.30 0.68];
        st.light = [0.78 0.86 0.96];
        st.marker = 'o';
        st.line = '-';
        st.name = 'Line';

    case 'wedge'
        st.color = [0.05 0.50 0.32];
        st.light = [0.78 0.92 0.84];
        st.marker = 's';
        st.line = '-';
        st.name = 'Wedge';

    case 'polygon'
        st.color = [0.82 0.37 0.10];
        st.light = [0.97 0.86 0.72];
        st.marker = '^';
        st.line = '-';
        st.name = 'Polygon';

    otherwise
        st.color = [0.20 0.20 0.20];
        st.light = [0.85 0.85 0.85];
        st.marker = 'o';
        st.line = '-';
        st.name = family;
end

end
