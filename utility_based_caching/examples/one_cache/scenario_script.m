%ciao
global severe_debug = true;
path_base = "~/software/araldo-phd-code/utility_based_caching";
addpath(sprintf("%s/scenario_generation",path_base) );
addpath(sprintf("%s/scenario_execution",path_base) );
addpath(sprintf("%s/scenario_generation/michele",path_base) );
addpath("~/software/araldo-phd-code/general/process_results" );
addpath("~/software/araldo-phd-code/general/optim_tools" ); % for launch_opl.m
pkg load statistics;


generate = true;
run_ = true;

% Define an experiment
experiment_name = "one_cache";

data.fixed_datas = [];
fixed_data.parallel_processes = 22;
fixed_data.path_base = path_base;
fixed_data.rate_per_quality = [0, 300, 700, 1500, 2500, 3500]; % In Kpbs
fixed_data.cache_space_at_low_quality = 11.25;% In MB

pp = 4;
fixed_data.utilities = [0**(1/pp)/5**(1/pp), 1**(1/pp)/5**(1/pp), 2**(1/pp)/5**(1/pp), 3**(1/pp)/5**(1/pp), 4**(1/pp)/5**(1/pp), 5**(1/pp)/5**(1/pp)];
fixed_data.name = "power4";
data.fixed_datas = [data.fixed_datas, fixed_data];


fixed_data.utilities = [0, 1/5, 2/5, 3/5, 4/5, 5/5 ];
fixed_data.name = "linear";
%data.fixed_datas = [data.fixed_datas, fixed_data];

data.topologys = [];
topology.ases = [1, 2];
topology.ases_with_storage = [2];
topology.ASes_with_users = [2];
topology.servers = [1];
peer_link_scales = [0];
for link_capacity = [490000] % In Kbps
	for peer_link_scale = peer_link_scales
		topology.link_capacity = link_capacity;
		topology.arcs = sprintf("{<1, 2, %g> };",link_capacity);
			topology.name = sprintf("onecache-%gMbps-peer-%g",link_capacity/1000, peer_link_scale);
			data.topologys = [data.topologys, topology];
	end % peer_link
end % link_capacity

data.cache_allocations = {"constrained"}; # constrained or free
data.solutiongaps = [0.01]; # default 0.0001 (that means 0.01%)
data.timelimits = [14400]; # default 1e75
data.seeds = [1];
data.catalog_sizes = [10000];
data.cache_to_ctlg_ratios = [0.001 0.01 0.1];	% fraction of catalog we could store in the cache if all 
						% the objects were at maximum quality
data.alphas = [1];



data.loadds = [0.1, 0.5, 0.8, 1, 1.2, 1.5, 2]; 	% Multiple of link capacity we would use to transmit 
				% all the requested objects at low quality
data.loadds = [0.5 1 2];

data.strategys = {"RepresentationAware", "NoCache", "AlwaysLowQuality", "AlwaysHighQuality", "AllQualityLevels", "DedicatedCache", "PropDedCache"};

data.strategys = {"RepresentationAware"};

launch_runs(experiment_name, data);


