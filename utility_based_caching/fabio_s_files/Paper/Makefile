#
# $Id: Makefile
#

LATEX=		latex
BIBTEX=		bibtex
DVIPDF=		dvipdft
DVIPS=		dvips
PSPDF=		ps2pdf
DATE=		`date '+%Y_%m_%d'`
FILE=		UtilityBasedCaching	
OUT=		UtilityBasedCaching
#OUT=		$(FILE)_$(DATE)

all: $(FILE).pdf

$(FILE).dvi: references 
	$(LATEX) $(FILE)

$(FILE).ps: $(FILE).dvi
	$(DVIPS) -Ppdf -G0 -tletter $(FILE).dvi

$(FILE).pdf: $(FILE).ps
	$(PSPDF) -dUseCIEColor -dPDFSETTINGS=/printer -dCompatibilityLevel=1.7 -dMaxSubsetPct=100 -dSubsetFonts=true -dEmbedAllFonts=true -sPAPERSIZE=letter $(FILE).ps $(OUT).pdf

references:
	$(LATEX) $(FILE) ; $(BIBTEX) $(FILE) ; $(LATEX) $(FILE);

clean:
	rm -f *.aux *.log *.toc *.bbl *.blg *.dvi *.ps *.pdf

name:
	echo $(FILE)
