% Ciao
global severe_debug = true;

addpath("michele");

% Define an experiment

ases = [1, 2];
quality_levels = [0, 1, 2];
catalog_size = 1000;
alpha = 1;
rate_per_quality = [0, 300, 3500]; % In Kpbs
cache_space_per_quality = [100000 11.25 131.25 ]; % In MB
utility_ratio = 2; % Ratio between low and high quality utility
utility_when_not_serving = 0;
ASes_with_users = [1];
server = 2;
load_ = 1.00;
total_requests = 1921 * load_;
arcs = "{<2, 1, 490000>};"; % In Kbps
max_storage_at_single_as = (catalog_size / 100) * \
						(cache_space_per_quality(2) + cache_space_per_quality(3) )/2  ; % IN MB
max_cache_storage = max_storage_at_single_as; % IN Mpbs
seeds = 1:10;

seed=1;
generate_opl_dat(ases, quality_levels, catalog_size, alpha, rate_per_quality, 
			cache_space_per_quality, utility_ratio, utility_when_not_serving, 
			ASes_with_users, server, total_requests,
			arcs, max_storage_at_single_as, max_cache_storage, seed);

