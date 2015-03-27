%ciao
addpath("~/software/araldo-phd-code/general/process_results");


che_output_folder = "/tmp";
outfolder = "/tmp";

priceratios = [1];
decisions = {"LRU" "pLRU","CoA"};
expression_for_cost_fraction = "grep -r \"cost_fraction\" %s/results-%s-pi_%g-seed_*.log | cut  -f6 | cut -d'=' -f2";
expression_for_hit_ratio = "grep -r \"phit_of_stage_0\" %s/results-%s-pi_%g-seed_*.log | cut -f3 | cut -f2 -d'='";
metrics = {"hit_ratio","cost_fraction"};

for j = 1:length(metrics)
	metric = metrics{j};
	switch (metric)
		case "hit_ratio"
			expression = expression_for_hit_ratio;
		case "cost_fraction"
			expression = expression_for_cost_fraction;
		otherwise
			error(sprintf("Metric %s is not valid", metric) );
	end

	for idx_decision = 1:length(decisions)
		decision = decisions{idx_decision};
		epression="";

		resume_local = [];
		for priceratio = priceratios
			command = sprintf(expression,che_output_folder, decision, priceratio);
			[status, output] = system(command,1);
			cost_fractions = str2num(output);
			mean_ = mean(cost_fractions);
			conf_ = confidence_interval(matr=cost_fractions, dim=1, ignore_NaN=false);
			line_ = [priceratio, mean_, conf_];
			resume_local = [resume_local; line_];
		end
		resume{idx_decision} = resume_local;
	end
	
	% Add priceratio column
	resume_local = resume{1};
	resume_total = resume_local(:,1);
	% Add mean values
	for idx_decision = 1:length(decisions)
		resume_local = resume{idx_decision};
		resume_total = [resume_total, resume_local(:,2) ]; % The second column is the mean
	end
	% Add another priceratio column
	resume_local = resume{1};
	resume_total = [resume_total, resume_local(:,1) ];
	% Add conf interval values
	for idx_decision = 1:length(decisions)
		resume_local = resume{idx_decision};
		resume_total = [resume_total, resume_local(:,3) ]; % The third column is the mean
	end
	filename = sprintf("%s/%s_che.dat", outfolder, metric);
	header="#priceratio LRU_mean pLRU_mean CoA_mean priceratio LRU_conf pLRU_conf CoA_conf";
	dlmwrite(filename,header,sep='');
	dlmwrite(filename, resume_total, sep=' ','-append');
	printf("File %s written\n", filename);
end
