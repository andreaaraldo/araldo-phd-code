function [ numOfRequestsPerClass, numOfRequestsPerObj ] = ZipfQuantizedRng( numOfObjects, numOfClasses, numOfRequestsSampled, zipf_alpha )
    printf("inside ZipfQuantizedRng\n");
    requestedObjects = ZipfRng(numOfRequestsSampled, zipf_alpha, numOfObjects);
    numOfRequestsPerObj = zeros(numOfObjects,1);
    numOfRequestsPerClass = zeros(numOfClasses,1);
    objsPerClass = numOfObjects/numOfClasses;
    
    for reqObj = requestedObjects'
        numOfRequestsPerObj(reqObj,1) = numOfRequestsPerObj(reqObj,1) + 1;
        numOfRequestsPerClass(1+floor((reqObj-1)/objsPerClass),1) = numOfRequestsPerClass(1+floor((reqObj-1)/objsPerClass),1) + 1;
    end
    printf("End of ZipfQuantizedRng\n");
end

