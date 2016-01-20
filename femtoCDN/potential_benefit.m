% simple test
opt = [800 200]';
opt = [0.28 0.28 0.28 0.04 0.02 0.02 0.02 0.02 0.02 0.02]' * 1000;

theta = repmat( sum(opt)/ length(opt), length(opt), 1)
meansq( theta-opt )
CV = sqrt( meansq( theta-opt ) ) ./ mean(theta)
err = norm(theta-opt) / norm(opt)
