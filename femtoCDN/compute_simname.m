%
function simname = compute_simname(settings, in)

								if strcmp(settings.method,"optimum_nominal")
									% These parameters do not influence the result and thus I 
									% keep a unique name
									settings.epochs = 1e6;
								end

								req_str=[];req_str_inner=[];
								if in.req_eps == -1
									%{ COMPATIBILITY WITH OLD VERSIONS
									if !exist("settings.compact_name","var")
										settings.compact_name=true;
									end
									%} COMPATIBILITY WITH OLD VERSIONS

									if settings.compact_name
										req_str_inner = sprintf("%g", std(in.req_proportion)*100);
									else
										req_str_inner = strrep(strrep(strrep(mat2str(in.req_proportion,2), "[", ""), "]","")," ","_");
										req_str_inner = strrep(req_str_inner, ";", "_");
									end
									req_str = sprintf("req_prop_%s",req_str_inner);
								else
									req_str_inner = sprintf("%g", in.req_eps);
									req_str = sprintf("req_eps_%s", req_str_inner);
								end

								timeev_str="";
								if in.ONtime<1
									timeev_str = sprintf("-ON_%gover%g",in.ONtime,in.ONOFFspan);
								elseif in.ONtime>1
									error "in.ONtime must be a fraction";
								end

	simname = sprintf("%s/p_%d-ctlg_%.1g-ctlg_eps_%g-alpha0_%g-alpha_eps_%g-lambda_%g-%s-T_%.1g-K_%.1g-%s-norm_%s-coeff_%s-projection_%s-boost_%g-tot_time_%g%s-seed_%d",...
	settings.mdat_folder,in.p,in.overall_ctlg,in.ctlg_eps, in.alpha0,   in.alpha_eps,   in.lambda,req_str, in.T,     in.K, settings.method, in.normalize_str, in.coefficients_str, settings.projection_str, settings.boost, in.tot_time,   timeev_str, settings.seed);
	
end
