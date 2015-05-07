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
experiment_name = "tree_general";

fixed_data.parallel_processes = 1;
fixed_data.path_base = path_base;
fixed_data.rate_per_quality = [0, 300, 700, 1500, 2500, 3500]; % In Kpbs
fixed_data.cache_space_at_low_quality = 11.25;% In MB
fixed_data.utilities = [sqrt(0)/sqrt(5), sqrt(1)/sqrt(5), sqrt(2)/sqrt(5), sqrt(3)/sqrt(5), sqrt(4)/sqrt(5), sqrt(5)/sqrt(5)];
fixed_data.name = "sqrt";
%data.fixed_datas = [fixed_data];

fixed_data.utilities = [0**(1/3)/5**(1/3), 1**(1/3)/5**(1/3), 2**(1/3)/5**(1/3), 3**(1/3)/5**(1/3), 4**(1/3)/5**(1/3), 5**(1/3)/5**(1/3)];
fixed_data.name = "cubic";
%data.fixed_datas = [fixed_data];

fixed_data.utilities = [0**(1/4)/5**(1/4), 1**(1/4)/5**(1/4), 2**(1/4)/5**(1/4), 3**(1/4)/5**(1/4), 4**(1/4)/5**(1/4), 5**(1/4)/5**(1/4)];
fixed_data.name = "power4";
%data.fixed_datas = [fixed_data];


fixed_data.utilities = [0, 1/5, 2/5, 3/5, 4/5, 5/5 ];
fixed_data.name = "linear";
%data.fixed_datas = [data.fixed_datas, fixed_data];
data.fixed_datas = [fixed_data];


data.topologys = [];
children = 2;
height = 4; # without considering the root
topology.link_capacity = 490000;  % In Kbps

size_ = floor( ( children**(height+1) - 1 ) / (children-1) );
topology.ases = 1:size_;
command = sprintf("%s/scenario_generation/graph_gen/tree.r %d %d %g", path_base, children, height, topology.link_capacity);
[status,output] = system(command);
if (status!=0) 
	error("Error in generating the tree");
end%if
lines = strsplit(output, del="\n");

topology.servers = [];
servers_str = strsplit(lines{1}, " ");
for idx = 1:length(servers_str )-1
	topology.servers = [topology.servers, str2num( servers_str{idx} ) ];
end %for

topology.ASes_with_users = [];
ASes_with_users_str = strsplit(lines{2}, " ");
for idx = 1:length(ASes_with_users_str )-1
	topology.ASes_with_users = [topology.ASes_with_users, str2num( ASes_with_users_str{idx} ) ];
end %for
topology.arcs = lines{3};

topology.ases_with_storage = 1:size_;
topology.ases_with_storage(topology.servers) = [];
topology.name = sprintf("height_%d-children_%d-capacity_%g-ubiquitous", ...
		height, children, topology.link_capacity);
%data.topologys = [data.topologys, topology];

topology.ases_with_storage = topology.ASes_with_users;
topology.name = sprintf("height_%d-children_%d-capacity_%g-edge", ...
		height, children, topology.link_capacity);
data.topologys = [data.topologys, topology];

data.seeds = [1];
data.catalog_sizes = [1000];

% fraction of catalog we could store in the cache if all 
% the objects were at maximum quality
data.cache_to_ctlg_ratios = [length(topology.ASes_with_users)/100];	
data.alphas = [1];


% Load on each AS with users attached
% It is expressed as a multiple of link capacity we would use to transmit 
% all the requested objects at low quality
data.loadds = [0.1, 0.5, 0.8, 1, 1.2, 1.5, 2]; 	
data.loadds = [1];


data.strategys = {"RepresentationAware", "NoCache", "AlwaysLowQuality", "AlwaysHighQuality", "AllQualityLevels", "DedicatedCache", "ProportionalDedicatedCache"};
data.strategys = {"RepresentationAware"};


launch_runs(experiment_name, data);


