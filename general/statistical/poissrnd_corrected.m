% The only difference with the original poissrnd is that we always force samples to be zero when
% the corresponding lambda is zero
function samples = poissrnd_corrected(lambas)
	samples = poissrnd(lambas) .* (lambdas>0);
end
