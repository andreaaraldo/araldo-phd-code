%ciao
addpath("~/software/araldo-phd-code/general/process_results");


che_output_folder = "/tmp/che_alpha";
outfolder = "/tmp/che_alpha";

priceratios = [10];

decisions = {"LRU" "pLRU","CoA"};

metrics = {"hit_ratio","cost_fraction","saving"};
metrics={"hit_ratio"};

alphas = 0.8:0.1:1.2;

expression_for_cost_fraction = "grep -r \"cost_fraction\" %s/results-%s-pi_%g-alpha_%g-seed_*.log | cut  -f6 | cut -d'=' -f2";
expression_for_hit_ratio = "grep -r \"phit_of_stage_0\" %s/results-%s-pi_%g-alpha_%g-seed_*.log | cut -f3 | cut -f2 -d'='";

for alpha = alphas
	for j = 1:length(metrics)
		metric = metrics{j};

		if strcmp(metric,"saving")
			%CHECK{
				if length(decisions)!=1 || decisions{1} != "CoA"
					error ("Saving can only be computed for CoA");
				end
			%}CHECK
			decision = decision = decisions{1};

			resume_local = [];
			for priceratio = priceratios
				expression = expression_for_cost_fraction;

				command = sprintf(expression,che_output_folder, "CoA", priceratio,alpha);
				[status, output] = system(command,1);
				cost_fraction_CoA = str2num(output);

				command = sprintf(expression,che_output_folder, "pLRU", priceratio,alpha);
				[status, output] = system(command,1);
				cost_fraction_pLRU = str2num(output);

				saving = (cost_fraction_pLRU .-  cost_fraction_CoA) ./ cost_fraction_pLRU;
				values_ = saving;

				mean_ = mean(values_);
				conf_ = confidence_interval(matr=values_, dim=1, ignore_NaN=false);
				line_ = [priceratio, mean_, conf_];
				resume_local = [resume_local; line_];
			end %for
			resume{1} = resume_local;
		
		else
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

				resume_local = [];
				for priceratio = priceratios
					command = sprintf(expression,che_output_folder, decision, priceratio,alpha);
					[status, output] = system(command,1);
					values_ = str2num(output);
					mean_ = mean(values_);
					conf_ = confidence_interval(matr=values_, dim=1, ignore_NaN=false);
					line_ = [priceratio, mean_, conf_];
					resume_local = [resume_local; line_];
				end
				resume{idx_decision} = resume_local;
			end
		end %if
	
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
		filename = sprintf("%s/%s_che-alpha_%g.dat", outfolder, metric,alpha);
		header="#priceratio LRU_mean pLRU_mean CoA_mean priceratio LRU_conf pLRU_conf CoA_conf";
		dlmwrite(filename,header,sep='');
		dlmwrite(filename, resume_total, sep=' ','-append');
		printf("File %s written\n", filename);
	end
end
