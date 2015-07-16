#! /usr/bin/octave -qf
addpath("~/software/araldo-phd-code/general/process_results" );


input_files = argv ();

pkg load statistics;
function mean_and_conf(input_files)
	% Get sizes
	sizes = size(dlmread(input_files{1} ) );
	table = zeros(sizes(1), sizes(2), length(input_files) );

	for i=1:length(input_files )
		file = input_files{i};
		table( :,:, i ) = dlmread(file);
	end %for
	table_mean = nanmean(table, 3);
	table_conf = confidence_interval(table, 3, ignore_NaN=true);

	maxitable = [];
	for i=1:size(table_mean,2)
		maxitable = [maxitable, table_mean(:,i), table_conf(:,i)];
	end %for
	disp(maxitable)
end %function

mean_and_conf(input_files);
