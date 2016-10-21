% Return known harmonic numbers
function harmonic_num = harmonic_num_lookup(ctlg_size, alpha)
	table = [1e8, 0.8, 0.0082538];
	score=sum( repmat([ctlg_size, alpha], size(table,1),1) == table(:,1:2), 2);
	entry = find(score==2);
	harmonic_num = table(entry,3);
end

%% Test code
harmonic_num = harmonic_num_lookup(1e8,0.7)
