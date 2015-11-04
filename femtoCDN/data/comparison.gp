set terminal postscript eps color
set output "comparison.eps"
set key outside


set xlabel "minutes"


plot "descent.dat"\
	using ($1/(9259.26*60 )):2 title "descent T=1080s" with points, \
""	using ($3/(9259.26*60 )):4 title "descent T=108s" with points, \
""	using ($5/(9259.26*60 )):6 title "descent T=10.8s" with points, \
""	using ($7/(9259.26*60 )):8 title "descent T=1.08s" with points, \


