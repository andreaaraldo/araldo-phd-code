function response = my_equality(a, b)
	threshold = 10^-15;	
	if abs(a-b)<threshold
		response = true;
	else
		response = false;
	end
end
