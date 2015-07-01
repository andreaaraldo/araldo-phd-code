function x = sample(distribution)
	switch distribution.type
		case "unif_discr"
			% All integers between a and b (both included) are equally probable
			a = distribution.a;
			b = distribution.b;
			x = floor( unifrnd(a,b+1) );
			if x > b
				error(["x is " x " and it is greater than b = " b]);
			endif

		case "unif_array"
			% All the elements of the array are equally probable
			index_distr.type = "unif_discr";
			index_distr.a = 1;
			index_distr.b = length(distribution.array);
			index = sample(index_distr);
			x = distribution.array(index);

		case "general_discr"
			% To the i-th element of the array is associated a probability p(i) to be
			% extracted
			v = distribution.array;
			p = distribution.p;

			% Check the consistency
			if length(v) != length(p)
				error("Erroneous distribution. v and p have 2 different lengths");
			endif

			if sum(p) != 1
				error(["Erroneous distribution. the sum of probabilities is " sum]);
			endif

			r = rand(1);

			cumulative = 0; i=0;
			while cumulative <= r
				i++;
				cumulative += p(i);
			endwhile
			x = v(i);

		otherwise
			error(["unknown distribution type: " distribution.type]);
	endswitch
endfunction
