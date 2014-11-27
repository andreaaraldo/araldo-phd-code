%<aa> purge: if true, remove redundant parenthesis </aa>
function opl_representation = opl_representation( variable_name, data, purge )
%<aa> variable_name: the name that will be printed in the file</aa>
%APPENDVARIABLETOOPLDAT Write variable in opl-like format

    varDimensions = size(data);
    elementsDimension = zeros(1,size(varDimensions,2));
    elementsFlipped = zeros(1,size(varDimensions,2));
    
    for i=1:size(varDimensions,2)
        index = size(varDimensions,2)-i+1;
        if (i == 1)
            elementsDimension(1,index)=1;
            elementsFlipped(1, i)=1;
        else
            elementsDimension(1,index)=elementsDimension(1,index+1)*varDimensions(1, index+1);
            elementsFlipped(1, i)=elementsFlipped(1,i-1)*varDimensions(1, i-1);
        end
    end
    
    items = numel(data); % <aa> number of elements of data </aa>
    
	%<aa>
	left_delimiter = "[";
	right_delimiter = "]";
	if (purge==true) && ( length(varDimensions)=2) && (varDimensions(1)==1 )
		% This is a vector
		left_delimiter = "";
		right_delimiter = "";
	end
	%</aa>


    opl_representation = sprintf('\n%s=%s', variable_name, left_delimiter) ;

	%<aa>
	if purge && isscalar(data)
		opl_representation = sprintf('%s %g;', opl_representation, data) ;
		return;
	end
	%</aa>

    for i=0:items-1
        v = sum(mod(floor(i./elementsDimension), varDimensions).*elementsFlipped)+1;
        
        for k=1:size(varDimensions,2)-1
            if (mod(i+1, elementsDimension(size(varDimensions,2)-k)) == 1 || (varDimensions(1,2)==1))
                opl_representation = sprintf('%s [ ', opl_representation);
            else
                break;
            end
        end
        
        opl_representation = sprintf('%s%g ', opl_representation, data(v));
        
        for k=1:size(varDimensions,2)-1
            if (mod(i+1, elementsDimension(size(varDimensions,2)-k)) == 0)
                opl_representation = sprintf('%s] ', opl_representation );
            else
                break;
            end
        end
    end
    
    opl_representation = sprintf('%s %s;\n', opl_representation, right_delimiter);
end

