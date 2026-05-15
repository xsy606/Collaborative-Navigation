function h = plot_error_ellipse(mu, Pxy, varargin)
%PLOT_ERROR_ELLIPSE Plot 95% confidence ellipse.

Pxy = 0.5 * (Pxy + Pxy.');

[V,D] = eig(Pxy);
lambda = real(diag(D));
lambda = max(lambda, 0);

[lambda, idx] = sort(lambda, 'descend');
V = V(:,idx);

chi2_95 = 5.99146454710798;

a = sqrt(chi2_95 * lambda(1));
b = sqrt(chi2_95 * lambda(2));

t = linspace(0, 2*pi, 250);
E = V * [a*cos(t); b*sin(t)] + mu(:);

h = plot(E(1,:), E(2,:), varargin{:});

end