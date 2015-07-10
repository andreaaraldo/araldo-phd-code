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
experiment_name = "multi_as";

data.fixed_datas = [];
fixed_data.parallel_processes = 8;
fixed_data.path_base = path_base;
fixed_data.rate_per_quality = [0, 300, 700, 1500, 2500, 3500]; % In Kpbs
fixed_data.cache_space_at_low_quality = 11.25;% In MB


fixed_data.utilities = [0, 1**(1/4)/5**(1/4), 2**(1/4)/5**(1/4), 3**(1/4)/5**(1/4), 4**(1/4)/5**(1/4), 5**(1/4)/5**(1/4)];
fixed_data.name = "power4";
data.fixed_datas = [data.fixed_datas, fixed_data];


fixed_data.utilities = [0, 1/5, 2/5, 3/5, 4/5, 5/5 ];
fixed_data.name = "linear";
data.fixed_datas = [data.fixed_datas, fixed_data];

%{TOPOLOGY
data.topologys = [];
size_ = 10;
edge_nodess = [5];
topology.link_capacity = 490000;  % In Kbps
topology_seed = 2;

topology.ases = 1:size_;
for edge_nodes = edge_nodess
	command = sprintf("%s/scenario_generation/graph_gen/barabasi.r %d %d %g %d",...
				 path_base, size_, edge_nodes, topology.link_capacity, topology_seed);
	[status,output] = system(command);
	lines = strsplit(output, del="\n");
	%{ CHECK
		if status!=0
			error(sprintf("Error in executing command %s", command) );
		end%if
	%} CHECK

	topology.ASes_with_users = [];
	ASes_with_users_str = strsplit(lines{1}, " ");
	for idx = 1:length(ASes_with_users_str )-1
		topology.ASes_with_users = [topology.ASes_with_users, str2num( ASes_with_users_str{idx} ) ];
	end %for
	topology.servers = topology.ASes_with_users;
	topology.arcs = lines{2};

	topology.ases_with_storage = 1:size_;
	topology.name = sprintf("size_%d-edgenodes_%d-capacity_%g-toposeed_%d-ubiquitous", ...
			size_, edge_nodes, topology.link_capacity, topology_seed);
	%data.topologys = [data.topologys, topology];

	topology.ases_with_storage = topology.ASes_with_users;
	topology.name = sprintf("size_%d-edgenodes_%d-capacity_%g-toposeed_%d-edge", ...
			size_, edge_nodes, topology.link_capacity, topology_seed);
	data.topologys = [data.topologys, topology];
end % for edge_nodes
%}TOPOLOGY

data.cache_allocations = {"constrained"}; # constrained or free
data.solutiongaps = [0.01]; # default 0.0001 (that means 0.01%)
data.timelimits = [28800]; # default 1e75
data.seeds = [1];
data.catalog_sizes = [1000];
data.cache_to_ctlg_ratios = [5/100];	% fraction of catalog we could store in the overall cache space
											% if all the objects were at maximum quality
data.alphas = [1];
data.customtypes = {"float"}; % float or int


% Load on each AS with users attached
% It is expressed as a multiple of link capacity we would use to transmit 
% all the requested objects at low quality
data.loadds = [0.1, 0.5, 0.8, 1, 1.2, 1.5, 2];
data.loadds = [2];


data.strategys = {"RepresentationAware", "NoCache", "AlwaysLowQuality", "AlwaysHighQuality", "AllQualityLevels", "DedicatedCache", "PropDedCache"};

launch_runs(experiment_name, data);


