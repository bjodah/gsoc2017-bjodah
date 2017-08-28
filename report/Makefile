.PHONY: all

all: report.html report.pdf

style.css: ../.binaries/cskeeters-rst2html-style.tar.bz2
	tar xjmf $< --wildcards --strip-components=1 "*/$@"

report.html: report.rst style.css rst2html.py
	python2 ./rst2html.py --stylesheet=style.css $< $@

report.tex: report.rst
	rst2latex.py $< $@

report.pdf: report.tex
	pdflatex $<
