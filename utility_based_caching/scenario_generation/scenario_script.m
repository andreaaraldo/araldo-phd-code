% Ciao
global severe_debug = true;


% Define an experiment

ases = [1, 2];
quality_levels = [0, 1, 2];
catalog_size = 2;
alpha = 1;
rate_per_quality = [0, 300, 3500]; % In Kpbs
cache_space_per_quality = [100000 11.25 131.25 ]; % In Mbps
utility_ratio = 2; % Ratio between low and high quality utility
ASes_with_users = [1];
server = 2;
total_requests = 10000;
arcs = "{<2, 1, 12>};";
max_storage_at_single_as = 132; % IN Mpbs
max_cache_storage = max_storage_at_single_as; % IN Mpbs




generate_opl_dat(ases, quality_levels, catalog_size, alpha, rate_per_quality, 
			cache_space_per_quality, utility_ratio, ASes_with_users, server, total_requests,
			arcs, max_storage_at_single_as, max_cache_storage);
