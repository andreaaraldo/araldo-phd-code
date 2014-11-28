% called by run_numerical_results.m
% 		as_probability:  as_probability[as] is the probability that a generic object is reachable through external
%						 link as
% 		replication:	vector. replication(i) is the ratio of objects that are replicated i times
function [object_reachability_matrix, replication] = generate_object_reachability_matrix(obj_num, as_probability, replication_admitted)

			global severe_debug

			as_num =length(as_probability);

			% {check_input_consistency
			if severe_debug
				if as_num != 3
					error(["as_num=",num2str(as_num)," while this code works only if as_num=3"]);
				end
			endif
			% }check_input_consistency


			object_reachability_matrix = zeros(as_num, obj_num);
			if replication_admitted
				for as = 1:as_num
					object_reachability_matrix(as,:) = \
							( rand (1,obj_num) <= as_probability(as) );
				endfor
			% else do nothing
				% Letting object_reachability_matrix be zeros, we force all objects to be not assigned. In
				% this way,
				% each one will be assigned to only one of the repositories (check the code later)
			endif


			not_assigned_objects = sum (object_reachability_matrix,1 ) == 0;
			new_assignment_prob = ( rand(1,obj_num) *sum(as_probability) ) .*  not_assigned_objects;

			previous = 0;
			for as = 1:as_num
				new_assignment =  \
						new_assignment_prob >  previous & new_assignment_prob <=  previous + as_probability(as);
				object_reachability_matrix(as,:) =  object_reachability_matrix(as,:) .+ new_assignment;
				previous += as_probability(as);
			endfor

			replication = zeros(1,as_num);
			for replica_num = 1:as_num
				replication(replica_num) = sum ( sum(object_reachability_matrix, 1 ) == replica_num ) / obj_num;
			endfor

			% {Check_obj_displacement
				if obj_num >= 1000
					% For the law of large numbers, the distribution of the number of objects 
					% reachable through each
					% external link should be similar to the probabilities associated to each link
					for as = 1:as_num
						following =  mod(as, as_num) + 1;
						if abs(\
								  abs(  sum(object_reachability_matrix(as,:)  ) - \
										sum(object_reachability_matrix(following,:) ) )  
									/ obj_num -\
								  abs( as_probability(as) - as_probability( following ) )\
						   ) > 0.1

							disp(["Number of objects reachable through each external links ",\
								num2str(as)," and ", num2str(following)," is"]);
							sum(object_reachability_matrix(as,:) )
							sum(object_reachability_matrix(following,:) )
							error(["discrepancy in the object distribution. This is not necessarily ",\
									"an error, but it is better to check"] ) ;
						endif
					endfor
				endif
			% }Check_obj_displacement

			% {OUTPUT_CHECK
			if severe_debug

				if any( size(replication) != [1,as_num] )
					replication
					as_num
					error("replication is malformed")
				endif

				if size(object_reachability_matrix,2) != obj_num
													size(object_reachability_matrix,2)
													obj_num
													error("Wrong obj num in object_reachability_matrix");
				endif


				not_assigned_objects = ( sum ( object_reachability_matrix,1 ) == 0 );
				if any (not_assigned_objects)
					not_assigned_objects
					object_reachability_matrix
					error("There are not assigned objects");
				end


				if obj_num >= 1000
				% {Check_obj_displacement
					% For the law of large numbers, the distribution of the number of objects reachable through each
					% external link should be similar to the probabilities associated to each link
					for as = 1:as_num
						following =  mod(as, as_num) + 1;
						if as_probability(as) == as_probability(following) && \
						  abs(\
						  abs( sum(object_reachability_matrix(as,:)  ) - sum(object_reachability_matrix(following,:) ) )/\
							obj_num -\
						  abs( as_probability(as) - as_probability( following ) )\
						   ) > 0.1

							disp(["Number of objects reachable through each external links ",num2str(as)," and ",\
								num2str(following)," is"]);
							sum(object_reachability_matrix(as,:) )
							sum(object_reachability_matrix(following,:) )
							error(["discrepancy in the object distribution. This is not necessarily an error, ",\
									"but it is better to check"] ) ;
						endif
					endfor
				% }Check_obj_displacement		
				endif
			endif
			% }OUTPUT_CHECK

end
