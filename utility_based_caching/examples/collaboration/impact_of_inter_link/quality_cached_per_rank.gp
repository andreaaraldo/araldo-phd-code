reset
<<<<<<< HEAD
set terminal postscript eps enhanced color
=======
set terminal postscript eps enhanced mono
>>>>>>> b0eabdccfbfcf887dd4703da6d696e9082d6a1cf
set output "quality_cached_per_rank.eps"
set yrange [0.9:2.1]
set xrange [0.9: 1001]

set multiplot layout 3, 1 title "Cached quality"
set ylabel "quality cached " 
set xlabel "rank"
set logscale x;

set title "Without peering link"
dat_file = "inter_link_0/seed_1/quality_cached_per_rank.csv"
plot dat_file \
<<<<<<< HEAD
	using 1:2 with points title "cache 1",\
''	using 1:3 with points title "cache 2";
=======
	using 1:2 with points title "cache 1" pointtype 2,\
''	using 1:3 with points title "cache 2" pointtype 6;

>>>>>>> b0eabdccfbfcf887dd4703da6d696e9082d6a1cf


set title "When peering link at 490Kbps"
dat_file = "inter_link_490000/seed_1/quality_cached_per_rank.csv"
plot dat_file \
	using 1:2 with points title "cache 1" pointtype 2,\
''	using 1:3 with points title "cache 2" pointtype 6;

set title "When peering link at 1Gbps"
dat_file = "inter_link_1e+06/seed_1/quality_cached_per_rank.csv"
plot dat_file \
	using 1:2 with points title "cache 1" pointtype 2,\
''	using 1:3 with points title "cache 2" pointtype 6;
