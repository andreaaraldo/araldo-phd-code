%ciao
addpath("~/software/araldo-phd-code/general/process_results");


che_output_folder = "~/software/araldo-phd-code/cost_aware/che/leondardi_c/risultati";
resume = [];

priceratios = [1, 2, 5, 10, 100];
decision = "CoA";
for priceratio = priceratios
	command = sprintf("grep -r \"cost_fraction\" %s/results-%s-pi_%g-seed_*.log | cut  -f6 | cut -d'=' -f2",
			che_output_folder, decision, priceratio);
	[status, output] = system(command,1);
	cost_fractions = str2num(output);
	mean_ = mean(cost_fractions);
	conf_ = confidence_interval(matr=cost_fractions, dim=1, ignore_NaN=false);
	line_ = [priceratio, mean_, conf_];
	resume = [resume; line_];
end
printf("#priceratio cost_fraction_mean cost_fraction_conf\n")
resume
