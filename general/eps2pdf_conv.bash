#!/bin/bash
FILE=$1
ps2pdf -dPDFSETTINGS=/prepress -dEPSCrop $FILE.eps
pdftk $FILE.pdf cat 1east output $FILE.pdf.tmp
mv $FILE.pdf.tmp $FILE.pdf
