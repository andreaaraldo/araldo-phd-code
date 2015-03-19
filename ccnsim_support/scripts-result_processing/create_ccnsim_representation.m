% Parse the output of greedy algorithm and represent the data in a file in the ccnsim
% form
function y = create_ccnsim_representation(selection_tuple,destination_folder,...
					optimization_result_folder)
	ctlg_transf= sprintf("%u",str2num(selection_tuple.ctlg) );
	cache_transf= sprintf("%u",str2num(selection_tuple.csize) );
	total_demand = sprintf("%u",1800*str2num(selection_tuple.ctlg)/1000 );
	asprob_ = selection_tuple.weights;
	priceratio_ = selection_tuple.priceratio;
	seed_ = num2str(selection_tuple.id_rep );
	alpha_ = selection_tuple.alpha;
	greedy_algo_folder = [optimization_result_folder,...
			"/wishset-model_ideal-cost-ctlg_",ctlg_transf,...
			"-cache_",cache_transf,"-priceratio_",priceratio_,...
			"-seed_",seed_,"-totaldemand_",total_demand,...
			"-alpha_",alpha_,"-asprob_",...
			asprob_];

	in_filename = [greedy_algo_folder,"/totalcost",".csv"];
	total_cost = csvread(in_filename);

	filename = [greedy_algo_folder,"/hitratio",".csv"];
	p_hit = csvread(in_filename);

	command = ["mkdir -p ",destination_folder];
	[status, output] = system(command,1);

	out_filename = [destination_folder,"/ccn-id", seed_,".sca"];

	[fid, msg]  = fopen(out_filename,"w");
	% CHECK{
	if (fid < 0)
		out_filename
		msg
		error(["Error opening file "]);
	endif
	% }CHECK

	fprintf(fid,"nothing nothing total_cost %d\n",total_cost);
	fprintf(fid,"nothing nothing p_hit[0] %d\n",p_hit);
	fclose(fid);
endfunction

