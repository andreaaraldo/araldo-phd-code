function popularity = generate_popularity(in)
	popularity = zeros(p, max(in.catalog) );
	for j=1:in.p
		switch in.popularity_generator
			case "zipf"
				popularity(j, 1:in.catalog(j)) = (ZipfPDF(in.alpha(j), in.catalog(j)) )';
			case "pareto"
				
		end
	end
end
