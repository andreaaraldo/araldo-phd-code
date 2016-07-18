function v = differentiated_vector(N, v0, v_eps)
	delta = 2.0 * v_eps * v0 / (N-1);
	v = repmat(v0 - v_eps * v0, N,1);
	for j=2:N
		v(j,1) = v(j,1) + (j-1)*delta;
	end
end
