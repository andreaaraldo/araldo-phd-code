Vertex caches_[] = {1,2,3,4,5,6,7,8,9,10,11};
Vertex repositories_[] = {8};
Vertex clients_[] = {1} ; //{5,6,7,1,10};
E edges_[] = {E(1,2), E(1,11), E(2,11), E(10,11), E(2,3),
		E(3,4), E(4,5), E(5,6), E(6,7), E(4,8), E(7,8), E(3,9), 
		E(8,9), E(9,10)};

Size link_capacity = 490.000; // In Mbps
Weight utilities[] = {67, 80, 88, 95, 100};
Size sizes[] = {0.300, 0.700, 1.500, 2.500, 3.500}; // In Mbps
