% behaviour_ can be "lfu" or "ideal"
function y = 	plot_cost_vs_hitratio( name, optimization, objective, cache_size, seed, catalog_size,\
									totaldemand, alpha,\
									core_router_cache_size, border_router_1_cache_size,\
									border_router_2_cache_size, price_ratio,totalcost, hitratio,\
									alpha_list, totaldemand_list, behaviour_list, catalog_size_list, \
									seed_list, cache_size_list, price_ratio_list, \
									as_probability_, asprob1,asprob2,asprob3)

	global severe_debug




	% {CHECK_INPUT_CONSISTENCY
	if severe_debug
		if length(price_ratio) != length(name)
			error(["length(price_ratio)=", num2str( length(price_ratio) ),"; length(name)=", num2str(length(name) ) ]  );
		end

	end
	% }CHECK_INPUT_CONSISTENCY


	for alpha_ = alpha_list
		for totaldemand_ = totaldemand_list
			for idx_behaviour = 1:length( behaviour_list )
				behaviour_ = behaviour_list(idx_behaviour);
				cost_savingXY = {};
				hitratio_lossXY = {};
				for catalog_size_ = catalog_size_list
					for cache_size_idx = 1:length(cache_size_list)
						cost_savingXY_over_seed = [];
						hitratio_lossXY_over_seed = [];
						for idx_seed = 1:length(seed_list)
							seed_ = seed_list(idx_seed);

							% Compute ratios{
								cache_size_ = cache_size_list(cache_size_idx);
								idx_incomplete = strcmp(optimization,behaviour_) & \
												cache_size == cache_size_ &  \
												seed == seed_ & catalog_size == catalog_size_;

								idx = idx_incomplete & totaldemand == totaldemand_ & alpha == alpha_ &\
									  asprob1 == as_probability_(1) & asprob2 == as_probability_(2) & \
									  asprob3 == as_probability_(3);

						
								% Consider only the price ratios inside the list
								idx = idx & ismember(price_ratio, price_ratio_list);
								idx_hitratio = idx & strcmp(objective, "hitratio");
								idx_cost = idx & strcmp(objective, "cost");
								totalcost_optimizing_hitratio = totalcost(idx_hitratio);
								totalcost_optimizing_cost = totalcost(idx_cost);
								hitratio_optimizing_hitratio = hitratio(idx_hitratio);
								hitratio_optimizing_cost = hitratio(idx_cost);
							% }Compute ratios
						
							% Verify correctness{
								if severe_debug
									if length(price_ratio) != length(name)
										error(["length(price_ratio)=", num2str( length(price_ratio) ),\
											"; length(name)=", num2str(length(name) ),". they must be the same" ]  );
									end
								end

								if severe_debug
									l1 = length( price_ratio(idx_hitratio) );
									l2 = length( price_ratio( idx_cost) );
									if (l1==0 || l2==0)
										disp("runs optimizing hitratio");
										name{idx_hitratio}
										disp("runs optimizing cost");
										name{idx_cost	}
										disp("alpha == alpha_")
										alpha == alpha_
										disp("totaldemand == totaldemand_")
										totaldemand == totaldemand_
										asprob1
										asprob2
										asprob3
										idx
										disp (["Before considering catalog_size  I found ",\
											num2str(length(price_ratio(cache_size == cache_size_ & \
											strcmp(optimization,behaviour_) & seed == seed_)) )," results"])
										disp (["With idx incomplete I find ",num2str(length(price_ratio(idx_hitratio)) ),\
															" results"])
										disp ( ["Found ", num2str(length(name) ) , " results. ", \
											num2str(l1)," results for MAX-HIT ", num2str(l2)," results for MIN-COST "])
										error( ["There are 0 results related to the MIN-COST problem ",\
											"or 0 results related to the MAX-HIT problem"] )
									end						

									if 		l1 != l2  || \
											! all (price_ratio(idx_hitratio) == price_ratio( idx_cost) )
									
										% catalog_size_
										% cache_size_
										% alpha
										% totaldemand
										seed_
										disp( [ "behaviour: ", behaviour_ ] ); 
										disp( "length(price_ratio(idx_hitratio) ):" );
										length(price_ratio(idx_hitratio) )
										disp( "length(price_ratio(idx_cost) ):" );
										length(price_ratio(idx_cost) )
										idx_cost
										idx_hitratio
										disp( "price_ratio(idx_hitratio)" );
										disp ( price_ratio(idx_hitratio) );
										disp( "price_ratio(idx_cost)" );
										disp( price_ratio(idx_cost) );
										error ("the price_ratios available with the hitratio optimization \
												are not the same as the price_ratios available with the \
												cost optimization");
									end

									if any(hitratio_optimizing_hitratio - hitratio_optimizing_cost < -1e-15)
										hitratio_optimizing_hitratio
										hitratio_optimizing_cost
										hitratio_optimizing_hitratio - hitratio_optimizing_cost
										error( strcat("hitratio_optimizing_hitratio seems less than ",
											"hitratio_optimizing_cost") );
									end

									if any(totalcost_optimizing_hitratio - totalcost_optimizing_cost < -1e-15)
										totalcost_optimizing_hitratio
										totalcost_optimizing_cost
										disp("difference=");
										totalcost_optimizing_hitratio - totalcost_optimizing_cost
										error( strcat("totalcost_optimizing_hitratio seems less than ",
											"totalcost_optimizing_cost") );
									end

								endif
							% }Verify correctness

							price_ratio_extracted = price_ratio(idx_cost);
							% Verify price_ratio_extracted
								if  ! all( ismember(price_ratio_extracted, price_ratio_list) ) ||\
									! all( ismember(price_ratio_list, price_ratio_extracted) )
									price_ratio_list
									price_ratio_extracted
									error( [ "For seed " num2str(seed_) " price ratio extracted is different from price " \
											"ratio list given as input"] );
								end
							% Verify price_ratio_extracted: end

							if idx_seed == 1
								% It's the first time that I'm filling the matrices
								% cost_savingXY_over_seed and hitratio_lossXY_over_seed
								% Therefore, I have to add the first column
								cost_savingXY_over_seed = price_ratio_extracted';
								hitratio_lossXY_over_seed = price_ratio_extracted';
							else
								% Check consistency{
								if severe_debug
									if  !isequal( cost_savingXY_over_seed(:,1), price_ratio_extracted' ) || \
										!isequal( hitratio_lossXY_over_seed(:,1), price_ratio_extracted' )


										idx_seed
										disp("price_ratio_extracted' is");
										price_ratio_extracted'
										costsavingXY_over_seed
										hitratio_lossXY_over_seed

										error("the first column of costsavingXY_over_seed and hitratio_lossXY_over_seed \
												must be the same as price_ratio_extracted' it's not the \
												 case");
									end
								endif
								% }Check consistency
							end
				
							cost_saving = (totalcost_optimizing_hitratio .- totalcost_optimizing_cost) ./ \
												 totalcost_optimizing_hitratio;
							hitratio_loss = (hitratio_optimizing_hitratio .- hitratio_optimizing_cost ) ./ \
												 hitratio_optimizing_hitratio;

							cost_savingXY_over_seed(:,idx_seed+1) = cost_saving';
							hitratio_lossXY_over_seed(:,idx_seed+1) = hitratio_loss';

							% Check consistency{
							if severe_debug
								if  !isequal( cost_savingXY_over_seed(:,1), price_ratio_extracted' ) || \
									!isequal( hitratio_lossXY_over_seed(:,1), price_ratio_extracted' )

									idx_seed
									disp("price_ratio_extracted' is");
									price_ratio_extracted'
									cost_savingXY_over_seed
									hitratio_lossXY_over_seed

									error(strcat( "the first column of cost_savingXY_over_seed and ",\
											"hitratio_lossXY_over_seed must be the same as ", 												"price_ratio_extracted' and it's not the case") );
								end

								if any(cost_saving < -1e-15) || any(hitratio_loss < -1e-15)
									cost_saving
									hitratio_loss
									error("there are some negative cost_saving or hitratio_loss");
								end
							end
							% }Check consistency


						end % seed loop


						% Remember that the first column of cost_savingXY_over_seed is the price ratio
						% The values of cost_saving start from column 2. 
						cost_saving = cost_savingXY_over_seed(:, 2:(length(seed_list)+1) );
						price_ratio_array = cost_savingXY_over_seed(:,1);
						% Compute the average cost_saving for each price ratio (along the seeds)
						% Therefore I have to compute a mean value for each row
						average_cost_saving = mean(cost_saving, 2);
						conf_in = confidence_interval( cost_saving, 2 );
						cost_savingXYZ{cache_size_idx} = [price_ratio_array, average_cost_saving, conf_in];

						% Repeat the same computation for hitratio_loss
						hitratio_loss = hitratio_lossXY_over_seed(:, 2:length(seed_list)+1 );
						price_ratio_array = hitratio_lossXY_over_seed(:,1);
						% Compute the average cost_saving for each price ratio (along the seeds)
						% Therefore I have to compute a mean value for each row
						average_hitratio_loss = mean(hitratio_loss, 2);
						conf_in = confidence_interval( hitratio_loss, 2 );
						hitratio_lossXYZ{cache_size_idx} = [price_ratio_array, average_hitratio_loss, conf_in];


					end % cache_size loop
				end % catalog loop

				% Generate plot
					colors = {'k','r','g','b','m','c'};
					markers ={'+','o','*','.','x','s'};
					x_label = "price ratio (log)";

					idx_metric = 1;
					cumulativeXYZ_list{idx_metric} = cost_savingXYZ;
					y_label{idx_metric} = "cost_savings";

					idx_metric = 2;
					cumulativeXYZ_list{idx_metric} = hitratio_lossXYZ;
					y_label{idx_metric} = "hitratio_loss";

					% metric can be cost or hitratio. One plot for each metric will be generated
					for idx_metric = 1:length(cumulativeXYZ_list)
						cumulativeXYZ = cumulativeXYZ_list{idx_metric};

						% Produce the table ready to be plotted with gnuplot
							out_filename = strcat(  "~/plot/",y_label{idx_metric},"-ctlg_",num2str(catalog_size_),\
													"-alpha_",num2str(alpha_),".dat");
							column_names = {"price_ratio"};
							for idx_cachesize = 1:length(cache_size_list)
								cs = cache_size_list(idx_cachesize);
								column_names{length(column_names)+1} = {\
										strcat(y_label{idx_metric},"_totcache_", num2str(cs)) };
								column_names{length(column_names)+1} = {\
										strcat("conf_intrvl","_totcache_", num2str(cs) ) };
							end

							fixed_variables = { alpha_; totaldemand_; catalog_size_;\
												behaviour_list{idx_behaviour}; as_probability_; seed_list; \
												 as_probability_ };
							fixed_variable_names = {"alpha_"; "totaldemand_"; "catalog_size_";\
													"behaviour_"; "as_probability_"; "seed_list";\
												 	"as_probability_" };

							% Construct the matrix to be transformed into table
								% Remember that cumulativeXYZ is a collection of matrices, one for each
								% cache size
								idx_cachesize = 1;
								matrix = cumulativeXYZ{idx_cachesize};

								for idx_cachesize = 2:length(cache_size_list)
									XYZtemp = cumulativeXYZ{idx_cachesize};
									% Ignore the first column of XYZtemp, since all the first columns of 
									% the matrices of the collection are always the same, namely they are
									% the price ratio
									value = XYZtemp(:,2);
									conf_interval = XYZtemp(:,3);
									matrix = [matrix, value, conf_interval];
								end
								
								% Order the rows of the matrix on the basis of the price ratio, i.e. the
								% 1st column
								matrix = sortrows(matrix,1);
							% end of Construct the matrix

							comment = [ "# The columns represent the ",y_label{idx_metric},\
										" at different cache ", \
										"budget values. Data are obtained with ",\
										"code/process_results/plot_cost_vs_hitratio" ];
							print_table(out_filename, matrix, column_names, fixed_variables,
											fixed_variable_names, comment);
						% end of Produce table

						plot_now = false;
						if plot_now
							figure
							for idx_cachesize = 1:length(cache_size_list)
								XYZ_temp = cumulativeXYZ{idx_cachesize};
								XYZ = sortrows(XYZ_temp,1);
								label = ["tot cache ", num2str(cache_size_list(idx_cachesize) ) ];
								errore = XYZ(:,3);
								myplot = errorbar( 	XYZ(:,1), XYZ(:,2), errore );
								set(myplot, "marker", markers{idx_cachesize} );
								set(myplot, "color",colors{idx_cachesize} );
								#set (gca, 'Xscale', 'log');
								title([ label,\
										"- obj placement:", behaviour_list(idx_behaviour) " - catalog size:"\
										num2str(catalog_size_) \
										" - totaldemand:" totaldemand_ " - alpha:" alpha_ ]);
								xlabel (x_label);
								ylabel (y_label{idx_metric} );
								set (gca, "ygrid", "on");
								set (gca, "xgrid", "on");
								hold on
							end

							% see http://psung.blogspot.fr/2009/05/making-gorgeous-latex-plots-with-octave.html
							print(["plot_cost_vs_hitratio_",num2str(idx_metric), ".tex"], '-dtex');

						end % of if plot_now
					end
				% end of Generate plot
			end
		end
	end
end
