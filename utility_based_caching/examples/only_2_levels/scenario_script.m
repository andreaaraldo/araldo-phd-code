%ciao
global severe_debug = true;
path_base = "~/software/araldo-phd-code/utility_based_caching";
addpath(sprintf("%s/scenario_generation",path_base) );
addpath(sprintf("%s/scenario_execution",path_base) );
addpath(sprintf("%s/scenario_generation/michele",path_base) );
addpath("~/software/araldo-phd-code/general/process_results" );
addpath("~/software/araldo-phd-code/general/optim_tools" ); % for launch_opl.m
pkg load statistics;
pkg load communications; % for randint



generate = true;
run_ = true;

% Define an experiment
experiment_name = "only_2_levels";

data.fixed_datas = [];
fixed_data.parallel_processes = 7;
fixed_data.path_base = path_base;
fixed_data.rate_per_quality = [0, 300, 3500]; % In Kpbs
fixed_data.cache_space_at_low_quality = 11.25;% In MB

fixed_data.utilities = [0**(1/4)/5**(1/4), 1**(1/4)/5**(1/4), 5**(1/4)/5**(1/4)];
fixed_data.name = "power4";
data.fixed_datas = [data.fixed_datas, fixed_data];


fixed_data.utilities = [0, 1/5, 5/5 ];
fixed_data.name = "linear";
data.fixed_datas = [data.fixed_datas, fixed_data];

%{TOPOLOGY
data.topologys = [];
topology.ases = [1, 2];
topology.ases_with_storage = [2];
topology.ASes_with_users = [2];
topology.servers = [1];
topology.link_capacity = 490000; %default link cap in Kbps
topology.arcs = sprintf("{<1, 2, %g> };", topology.link_capacity);
topology.name = sprintf("onecache-%gMbps", topology.link_capacity/1000);
		data.topologys = [data.topologys, topology];
%}TOPOLOGY

data.cache_allocations = {"free"}; # free or constrained
data.solutiongaps = [0.01]; # default 0.0001 (0.01%)
data.timelimits = [7200]; # default 1e75
data.seeds = [1];
data.catalog_sizes = [1000];
data.cache_to_ctlg_ratios = [1/100];	% fraction of catalog we could store in the cache if all 
						% the objects were at maximum quality
data.alphas = [1];


% Load on each AS with users attached
% It is expressed as a multiple of link capacity we would use to transmit 
% all the requested objects at low quality
data.loadds = [0.1, 0.5, 0.8, 1, 1.2, 1.5, 2]; 	


data.strategys = {"RepresentationAware", "NoCache", "AlwaysLowQuality", "AlwaysHighQuality", "AllQualityLevels", "DedicatedCache", "PropDedCache"};


launch_runs(experiment_name, data);


