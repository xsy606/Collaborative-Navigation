function met = metrics_from_P(Pxy)
%METRICS_FROM_P Convert 2D covariance into RMSE and 95% ellipse metrics.

Pxy = 0.5 * (Pxy + Pxy.');

[V,D] = eig(Pxy); %#ok<ASGLU>
lambda = real(diag(D));
lambda = max(lambda, 0);
lambda = sort(lambda, 'descend');

if numel(lambda) < 2
    lambda = [lambda; 0];
end

chi2_95 = 5.99146454710798;

met.rmse_xy = sqrt(max(trace(Pxy), 0));
met.major95 = sqrt(chi2_95 * lambda(1));
met.minor95 = sqrt(chi2_95 * lambda(2));
met.area95 = pi * met.major95 * met.minor95;
met.condnum = (lambda(1) + eps) / (lambda(2) + eps);

end