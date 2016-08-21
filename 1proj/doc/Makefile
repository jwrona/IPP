NAME = CST-doc
.SUFFIXES: .tex .dvi .pdf

.tex.dvi:
	latex $(NAME).tex

.dvi.pdf:
	dvipdf $(NAME).dvi

all: $(NAME).pdf
	
clean:
	rm $(NAME).aux $(NAME).dvi $(NAME).log
