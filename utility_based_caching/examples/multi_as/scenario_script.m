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
%data.fixed_datas = [data.fixed_datas, fixed_data];

data.topology_size = 2;
data.edge_nodess = [1];
data.server_positions = {"complement_to_edges"}; %"complement_to_edges" or "edges" 
data.link_capacity = 490000;  % In Kbps
data.seeds = [1 2];



data.cache_allocations = {"constrained"}; # constrained or free
data.solutiongaps = [0.01]; # default 0.0001 (that means 0.01%)
data.timelimits = [28800]; # default 1e75
data.catalog_sizes = [100000];
data.cache_to_ctlg_ratios = [1/100];	% fraction of catalog we could store in the overall cache space
											% if all the objects were at maximum quality
data.alphas = [1];
data.customtypes = {"float"}; % float or int
data.cache_distributions = {"edge"}; % edge or ubiquitous


% Load on each AS with users attached
% It is expressed as a multiple of link capacity we would use to transmit 
% all the requested objects at low quality
data.loadds = [0.25 0.50 0.75 1.00 1.25 1.50 1.75 2.00];


data.strategys = {"RepresentationAware", "NoCache", "AlwaysLowQuality", "AlwaysHighQuality", "AllQualityLevels", "DedicatedCache", "PropDedCache"};

data.path_base= path_base;
launch_runs(experiment_name, data);


