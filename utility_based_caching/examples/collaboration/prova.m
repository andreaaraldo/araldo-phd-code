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
experiment_name = "collaboration";

fixed_data.parallel_processes = 7;
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
topology.ases = [1, 2, 3];
topology.ases_with_storage = [2, 3];
topology.ASes_with_users = [2, 3];
topology.server = 1;
peer_link_scales = [0, 0.5, 0.8, 1, 1.2, 1.5, 2, 5];
peer_link_scales = [1];
for link_capacity = [490000] % In Kbps
	for peer_link_scale = peer_link_scales
		topology.link_capacity = link_capacity;
		peer_capacity = link_capacity * peer_link_scale;
		topology.arcs = sprintf("{<1, 2, %g>, <1, 3, %g>, <2, 3, %g>, <3, 2, %g> };",...
				link_capacity,link_capacity, peer_capacity, peer_capacity);
			topology.name = sprintf("triangles-%gMbps-peer-%g",link_capacity/1000, peer_link_scale);
			data.topologys = [data.topologys, topology];
	end % peer_link
end % link_capacity

data.seeds = [1,2];
data.catalog_sizes = [10];
data.cache_to_ctlg_ratios = [2/100];	% fraction of catalog we could store in the cache if all 
						% the objects were at maximum quality
data.alphas = [1];


% Load on each AS with users attached
% It is expressed as a multiple of link capacity we would use to transmit 
% all the requested objects at low quality
data.loadds = [0.1, 0.5, 0.8, 1, 1.2, 1.5, 2]; 	
data.loadds = [1];


data.strategys = {"RepresentationAware", "NoCache", "AlwaysLowQuality", "AlwaysHighQuality", "AllQualityLevels", "DedicatedCache", "ProportionalDedicatedCache"};
data.strategys = {"RepresentationAware"};

launch_runs(experiment_name, data);


