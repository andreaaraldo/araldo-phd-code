%ciao
addpath("~/software/araldo-phd-code/general/process_results");


che_output_folder = "~/software/araldo-phd-code/cost_aware/che/leondardi_c/risultati";
outfolder = "/tmp";

priceratios = [1, 2, 5, 10, 100];
decisions = {"LRU","pLRU","CoA"};
expression_for_cost_fraction = "grep -r \"cost_fraction\" %s/results-%s-pi_%g-seed_*.log | cut  -f6 | cut -d'=' -f2";
expression_for_hit_ratio = "grep -r \"phit_of_stage_0\" %s/results-%s-pi_%g-seed_*.log | cut -f3 | cut -f2 -d'='";
metrics = {"hit_ratio","cost_fraction"};

for i = 1:length(decisions)
	for j = 1:length(metrics)
		decision = decisions{i};
		metric = metrics{j};
		epression="";

		switch (metric)
			case "hit_ratio"
				expression = expression_for_hit_ratio;
			case "cost_fraction"
				expression = expression_for_cost_fraction;
			otherwise
				error(sprintf("Metric %s is not valid", metric) );
		end

		resume = [];
		for priceratio = priceratios
			command = sprintf(expression,che_output_folder, decision, priceratio);
			[status, output] = system(command,1);
			cost_fractions = str2num(output);
			mean_ = mean(cost_fractions);
			conf_ = confidence_interval(matr=cost_fractions, dim=1, ignore_NaN=false);
			line_ = [priceratio, mean_, conf_];
			resume = [resume; line_];
		end
		filename = sprintf("%s/%s_%s_che.dat", outfolder, metric, decision);
		dlmwrite(filename, resume, sep=' ');
		printf("File %s written\n", filename);
	end
end
