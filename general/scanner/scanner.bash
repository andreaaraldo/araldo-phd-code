FILE=$1
sane-find-scanner
scanimage 	-L
scanimage --resolution 300 --mode Gray --brightness -20 --contrast 15 > $FILE.pnm

#convert *.pnm output.pdf
