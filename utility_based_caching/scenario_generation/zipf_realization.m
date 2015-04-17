% Andrea: inspired by ZipfQuantizedRng of Michele
function [ numOfRequestsPerClass, numOfRequestsPerObj ] = zipf_realization( numOfObjects, numOfClasses, numOfRequestsSampled, zipf_alpha )
    requestedObjects = generate_requests(numOfRequestsSampled, zipf_alpha, numOfObjects);
    numOfRequestsPerObj = zeros(numOfObjects,1);
    numOfRequestsPerClass = zeros(numOfClasses,1);
    objsPerClass = numOfObjects/numOfClasses;
    
    for reqObj = requestedObjects'
        numOfRequestsPerObj(reqObj,1) = numOfRequestsPerObj(reqObj,1) + 1;
        numOfRequestsPerClass(1+floor((reqObj-1)/objsPerClass),1) = numOfRequestsPerClass(1+floor((reqObj-1)/objsPerClass),1) + 1;
    end
end

