function y = plot_cache_sizing( optimization, objective, cache_size, seed, catalog_size, totaldemand, \
								alpha, core_router_cache_size, border_router_1_cache_size,\
								border_router_2_cache_size, border_router_3_cache_size, price_ratio, \
								alpha_list, totaldemand_list, catalog_size_list, seed_list,\
								cache_size_list, behaviour_list, objective_list, \
								as_probability_, asprob1,asprob2,asprob3)

	global severe_debug;

	cache_position_num = 4; % The cache positions are core, border1, border2, border3

	for alpha_ = alpha_list
		for totaldemand_ = totaldemand_list
			for catalog_size_ = catalog_size_list
				for cache_size_idx = 1:length(cache_size_list)
					for behaviour_ = behaviour_list
						for objective_ = objective_list

							for idx_seed = 1:length(seed_list)
								seed_ = seed_list(idx_seed);
								cache_size_ = cache_size_list(cache_size_idx);
								idx_incomplete = strcmp(optimization,behaviour_) & \
										cache_size == cache_size_ & \
										seed == seed_ & catalog_size == catalog_size_;
								idx = idx_incomplete & totaldemand == totaldemand_ & alpha == alpha_ & \
										strcmp(objective, objective_);
%								idx = idx & strcmp(optimization, "lfu");\
								cache_sizes = [	core_router_cache_size(idx); \
												border_router_1_cache_size(idx); \
												border_router_2_cache_size(idx); border_router_3_cache_size(idx) ]';

								% {CHECK_CONSISTENCY
									% Verify that all the cache size is used
									if severe_debug
										if cache_position_num != size(cache_sizes,2)
											error("I expected 4 caches");
										end

										if any( sum(cache_sizes, 2) != cache_size_ )
											cache_sizes
											cache_size_
											error("Error in the computation of cache sizes")
										end
									end
								% }CHECK_CONSISTENCY
								price_ratio_extracted = price_ratio(idx);

								% {Contruct XY_over_seed matrices
									% We construct different XY_over_seed matrices, one for each cache position (core,
									% border1, border2, border3). The first column of XY_over_seed is the price ratio.
									% Then there is a column for each seed. Each of these column indicates the cache 
									% size allocated to that position with that seed
									for idx_cache_position = 1:cache_position_num
										% It's the first time that I'm filling each matrix. I initialize each with
										% the values that come out with the first seed
										if idx_seed == 1
											XY_over_seed{idx_cache_position} = \
												[price_ratio_extracted' , cache_sizes(:,idx_cache_position)];
										else
											% I add a new colums with the values related to the new seed
											XY_over_seed{idx_cache_position} = \
												[XY_over_seed{idx_cache_position}, cache_sizes(:,idx_cache_position) ];
										end

										% {CHECK_CONSISTENCY
												% The price ratio must be always the same, whatever seed
												if severe_debug
													if any (XY_over_seed{idx_cache_position}(:,1)!= price_ratio_extracted' )
														disp("price ratio extracted");
														price_ratio_extracted'
														disp("XY_over_seed{idx_cache_position}");
														XY_over_seed{idx_cache_position}
														error("error in the computation of the price ratio")
													end
												end
										% }CHECK_CONSISTENCY
									end
								% }Contruct XY_over_seed matrices
							endfor % seed loop

								% {Construct XY matrices
									% Now, we reduce each XY_over_seed matrix{idx_cache_position} in a matrix 
									% XY{idx_cache_position} with three columns: 
									%		price_ratio, average_cache_size, confidence_interval
									for idx_cache_position = 1:cache_position_num
										price_ratio_column = XY_over_seed{idx_cache_position}(:,1);
										this_cache_size = \
													XY_over_seed{idx_cache_position}(:,2:length(seed_list) + 1 );
										average_cache_size = mean(this_cache_size,2);
										conf_interval = confidence_interval( this_cache_size, 2 );
										XY{idx_cache_position} = [price_ratio_column, average_cache_size, conf_interval];
									end
								% }Construct XY matrices


								% {Contruct matrix
									% We construct now the matrix we are going to print

									% The price_ratio column is the same for all the cache positions, 
									% so I can indifferently use the one that was calculated the last
									matrix = price_ratio_column;

									for idx_cache_position = 1:cache_position_num
										% Add the average cache size column
										matrix = [matrix, XY{idx_cache_position}(:,2)] ;

										% Add the confidence interval column
										matrix = [matrix, XY{idx_cache_position}(:,3)] ;
									end 
								% }Contruct matrix


								out_filename = ["~/plot/cache_sizing-alpha_",num2str(alpha_),".dat"];
								column_names = {"price_ratio", "core_size", "conf_intrvl", "bord_1_size", "conf_intrvl",\
												"bord_2_size", "conf_intrvl", "bord_3_size", "conf_intrvl", };
								fixed_variables = { alpha_; totaldemand_; catalog_size_; seed_list;\
													cache_size_idx; behaviour_{1}; objective_{1}; \
													as_probability_};
								fixed_variable_names = {"alpha_"; "totaldemand_"; "catalog_size_"; "seed_list"; \
														"cache_size_idx"; "behaviour_"; "objective_"; \
														"as_probability_"};
								matrix = sortrows(matrix,1);
								comment = "Data are obtained with code/process_results/plot_cache_sizing";
								print_table(out_filename, matrix, column_names, fixed_variables,
												fixed_variable_names, comment);
								plot_now = false;

								if plot_now							
									bar( 1:size(XY,1), XY(:,2:4) );
									set(gca, 'XTick', 1:size(XY,1), "XTickLabel", num2str(XY(:,1) ) );
									xlabel ("price ratio");
									ylabel ("cache size (num of obj)" );
									legend('core','border 1', 'border 2', 'border 3');
									title(["CACHE SIZING\n", "- obj placement:", behaviour_ " - catalog size:"\
											num2str(catalog_size_) \
											" - totaldemand:" totaldemand_ " - alpha:" alpha_ ]);
									% see http://psung.blogspot.fr/2009/05/making-gorgeous-latex-plots-with-octave.html
									print(["plot_cache_sizing.tex"], '-dtex');
								end
						end
					end
				end
			end
		end
	end
end
