% metric_vs_priceratio
function y = scatter_plot (parsed)
	global severe_debug;
	
	out_filename = "/tmp/scatter.dat";

	 [fid, msg]  = fopen(out_filename,"w");
	% CHECK{
	if (fid < 0)
		out_filename
		msg
		error(["Error opening file "]);
	endif
	% }CHECK

	% Print the field names
	fields = fieldnames(parsed(1)) ;
	fprintf(fid, "#");
	for field_idx = 1:length(fields)
		fprintf(fid, "%d.%s ",field_idx, fields{field_idx} );
	endfor
	fprintf(fid, "\n");

	for simu_idx = 1:length(parsed)
		simu = parsed(simu_idx);
		for field_idx = 1:length(fields)
			field = fields{field_idx};
			value = getfield(simu,num2str(field ) );
			if isequal(value,NaN)
				value = "NaN";
			elseif isscalar(value)
				value = num2str(value);
			end
			fprintf(fid, "%s ",value  );
		endfor
		fprintf(fid, "\n");
	endfor
	fclose(fid);
	disp(["Data has been written on ", out_filename] );
endfunction
