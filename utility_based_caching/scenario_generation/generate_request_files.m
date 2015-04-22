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
				total_requests = total_requests = ...
					singledata.loadd *  ...
					singledata.topology.link_capacity / singledata.fixed_data.rate_per_quality(2);
				number_of_object_classes = singledata.catalog_size;
				num_of_req_at_each_as = round(total_requests / length(singledata.topology.ASes_with_users) );

				time1 = time();
				[requests_for_each_class, requests_for_each_object] = zipf_realization(
					singledata.catalog_size, number_of_object_classes, num_of_req_at_each_as, singledata.alpha);
				time2 = time();
				% printf("Requests generated in %g seconds\n",time2-time1);
				% Replace zipf_realization with ZipfQuantizedRng if you want to use Michele's code

				requests_at_each_AS.obj = 1:singledata.catalog_size;
				requests_at_each_AS.req_num = requests_for_each_object;
				requests.ASes = singledata.topology.ASes_with_users;
				ObjRequests = sprintf("ObjRequests = { ");
				for i = 1:length(singledata.topology.ASes_with_users)
					as = singledata.topology.ASes_with_users(i);
					for j = 1:singledata.catalog_size
						obj = requests_at_each_AS.obj(j);
						req_num = requests_at_each_AS.req_num(j);
						ObjRequests = sprintf("%s <%g,%g,%g>,",ObjRequests, obj, as, req_num);
					endfor
				endfor
				ObjRequests = sprintf("%s};",ObjRequests);
				ObjRequests(length(ObjRequests)-2) = " ";
				fprintf(f_req, "%s\n",ObjRequests);
				fclose(f_req);
				exit(0);

			elseif (pid > 0)
				% I am the father
				active_children ++;
			else (pid < 0)
				error ("Error in forking");
			endif



		% else The request file already exists. Do nothing
		endif % request_file existence

	end % for

	% Wait for the remaining active children
	while (active_children > 0)
		printf("Waiting for %d processes to finish\n", active_children);
		waitpid(-1);
		active_children--;
	end % while

endfunction
