% Modified version of Michele Mangili's code
function [P_zipf, lambda_obj, pHitChe, pHitCheAvg] = che()

% Che's Approximation

% N = input('Insert Content Catalog Cardinality: ');
% B = input('Insert Cache Size: ');
% lambda_tot = input('Insert the Aggregated Request Arrival Rate: ');
% alpha = input('Insert the Zipf Exponent: ');

% Generation of truncated Zipf distribution

N = 10000;
B = 100;
lambda_tot = 4;
alpha = 1;

P_zipf = zeros(1,N);
norm_factor = 0;
for i=1:N
    norm_factor = norm_factor + (1/i^alpha);
end

norm_factor = 1 / norm_factor;

for i=1:N
    P_zipf(1,i) = norm_factor * (1/i^alpha);
end 

%% FIRST CACHE

%Calculate the Mean Interarrival Rate per each content

lambda_obj = zeros(1,N);
for i=1:N
    lambda_obj(1,i) = P_zipf(1,i) * lambda_tot;
end

TC = 0;

syms x;
TC = solve(sum(1-exp(-lambda_obj(1,1:N).*x)) == B);
%S = solve(sum(1-exp(-P_zipf(1,1:N).*x)) == B);

pHitChe = zeros(1, N);

for i=1:N
    pHitChe(1,i) = 1-exp(-lambda_obj(1,i)*TC);
end

pHitCheAvg = mean(pHitChe(1,:));
