% ciao
function [zipf] = generate_zipf(alpha, obj_num)
		zipf.distr = (1:obj_num).^alpha;
		zipf.distr = 1./zipf.distr;
		harm_num = sum(zipf.distr);
		zipf.distr = zipf.distr ./ harm_num;
		zipf.alpha = alpha;
		zipf.obj_num = obj_num;
		
%		C = obj_num/100;
%		coso = zipf.distr .* (zipf.distr .- (1.-zipf.distr).^C );
%		sum(coso)
end
