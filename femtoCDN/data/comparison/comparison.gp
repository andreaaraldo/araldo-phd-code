set terminal postscript eps color
set output "comparison.eps"
set key outside


set xlabel "minutes"


plot\
"descent_ep1e1.dat"	u ($1/(9259.26*60 )):2 title "descent T=1080s" with points, \
"descent_ep1e2.dat"	u ($1/(9259.26*60 )):2 title "descent T=108s" with points, \
"descent_ep1e3.dat"	u ($1/(9259.26*60 )):2 title "descent T=10.8s" with points, \
"descent_ep1e4.dat"	u ($1/(9259.26*60 )):2 title "descent T=1.08s" with points, \
"optimum.dat" u ($1/(9259.26*60 )):2 title "optimum" with lines


