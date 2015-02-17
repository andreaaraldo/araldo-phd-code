%<aa> filename now replaces file </aa>
function [  ] = AppendVariableToOPLDat( filename, variable_name, data )
%<aa> variable_name: the name that will be printed in the file</aa>
%APPENDVARIABLETOOPLDAT Write variable in opl-like format

	%<aa> 
	file = fopen(filename,"w");
	%</aa>

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
    
    items = numel(data);
    
    fprintf(file, sprintf('\n%s=[', variable_name));
    
    for i=0:items-1
        v = sum(mod(floor(i./elementsDimension), varDimensions).*elementsFlipped)+1;
        
        for k=1:size(varDimensions,2)-1
            if (mod(i+1, elementsDimension(size(varDimensions,2)-k)) == 1 || (varDimensions(1,2)==1))
                fprintf(file, '[ ');
            else
                break;
            end
        end
        
        fprintf(file, '%d ', data(v));
        
        for k=1:size(varDimensions,2)-1
            if (mod(i+1, elementsDimension(size(varDimensions,2)-k)) == 0)
                fprintf(file, '] ');
            else
                break;
            end
        end
    end
    
    fprintf(file, '];\n');

	%<aa> 
	file = fclose(filename);
	%</aa>
end

