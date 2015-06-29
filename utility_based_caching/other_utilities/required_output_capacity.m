%ciao
path_base = "~/software/araldo-phd-code/utility_based_caching";
addpath(sprintf("%s/scenario_generation",path_base) );


N = 1000;
alpha = 1;
c2ctlg = 1/100;
L = 490; % link capacity in Mbps
rate_at_min_q = 0.300;
rate_at_max_q = 3.500;
req_tot = ;
z = ZipfPDF( alpha, N );
cumulative = sum( z(1: floor(N*c2ctlg ) ) );
req_to_cache = req_tot * cumulative;
required_L_ratio = req_to_cache * rate_at_max_q / L;

required_L_ratio = cumulative * req_tot * rate_at_max_q / rate_at_min_q ;
