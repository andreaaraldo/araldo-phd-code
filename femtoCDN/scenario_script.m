%The algoritm implemented here is inspired by
% Megory-Cohen, Igal and Ela, Givat - "Dynamic Cache Partitioning by Modified Steepest Descent" 
global severe_debug = 1;
addpath("~/software/araldo-phd-code/utility_based_caching/scenario_generation");
%pkg load statistics;
%pkg load communications; % for randint


% INPUT PARAMETERS
in.alpha=[0.8; 1.2];
in.R = [1e6; 1e6 ];
in.catalog=[1e3; 1e3];
in.K = 1e1; %cache slots


cumulative_steepest_descent(in)
