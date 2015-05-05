% Called by scenario_script.m
function generate_request_files(run_list)
	active_children = 0;



	for idx_run = 1:length(run_list)
		singledata = run_list(idx_run);
		if ( !exist(singledata.request_file) )

			if (active_children == singledata.fixed_data.parallel_processes)
				waitpid(-1);
				% One child process finished
				active_children--;
			endif
			pid = fork();
			if (pid==0)
				% I am the child process and I generate the run
				f_req = fopen(singledata.request_file, "w");
				if (f_req==-1)
					error(sprintf("Error in writing file %s",singledata.request_file) );
				endif

				rand("state",singledata.seed);
				num_of_req_at_each_as =  ...
					singledata.loadd *  ...
					singledata.topology.link_capacity / singledata.fixed_data.rate_per_quality(2);
				number_of_object_classes = singledata.catalog_size;
				total_requests = num_of_req_at_each_as * length(singledata.topology.ASes_with_users);

				time1 = time();
				[requests_for_each_class, requests_for_each_object] = zipf_realization(
					singledata.catalog_size, number_of_object_classes, total_requests, singledata.alpha);
				rnd_matrix = rand( ( length(singledata.topology.ASes_with_users) -1) , singledata.catalog_size);
				rnd_matrix = sort(rnd_matrix, 1);
				rnd_matrix = [zeros(1,singledata.catalog_size); rnd_matrix];
				rnd_matrix = [rnd_matrix; ones(1,singledata.catalog_size)];
				time2 = time();
				% printf("Requests generated in %g seconds\n",time2-time1);
				% Replace zipf_realization with ZipfQuantizedRng if you want to use Michele's code

				requests_at_each_AS.req_num = requests_for_each_object;
				requests.ASes = singledata.topology.ASes_with_users;
				ObjRequests = sprintf("ObjRequests = { ");
				for as_idx = 1:length(singledata.topology.ASes_with_users)
					as = singledata.topology.ASes_with_users(as_idx);
					printf("Ciao, considering as %d", as);
					fraction_of_requests = ( rnd_matrix(as_idx+1,:) - rnd_matrix(as_idx,:) )';
					requests_at_as = round( fraction_of_requests .* requests_for_each_object );

					for obj = 1:singledata.catalog_size
						req_num = requests_at_as(obj);
						ObjRequests = sprintf("%s <%g,%g,%g>,",ObjRequests, obj, as, req_num);
					endfor
				endfor
				ObjRequests = sprintf("%s};",ObjRequests);
				ObjRequests(length(ObjRequests)-2) = " ";
				fprintf(f_req, "%s\n",ObjRequests);
				fclose(f_req);

				% Write the req_frac_for_each_object_file
				req_frac_for_each_object_file = sprintf("%s-req_frac_for_each_object.csv", singledata.request_file);
				fid = fopen(req_frac_for_each_object_file, "w+");
				fprintf(fid, "#requests\n");
				fclose(fid);
				dlmwrite(req_frac_for_each_object_file, requests_for_each_object ./ total_requests,...
						 "append","on", "delimiter"," " );

				exit(0);


			elseif (pid > 0)
				% I am the father
				active_children ++;
			else (pid < 0)
				error ("Error in forking");
			endif

		else
			printf("The fgile exists\n")

		% else The request file already exists. Do nothing
		endif % request_file existence

	end % for

	% Wait for the remaining active children
	while (active_children > 0)
		printf("Waiting for %d generation processes to finish\n", active_children);
		waitpid(-1);
		active_children--;
	end % while

endfunction
