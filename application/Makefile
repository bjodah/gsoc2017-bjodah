.PHONY: all

all: proposal.html proposal.pdf

style.css: ../.binaries/cskeeters-rst2html-style.tar.bz2
	tar xjf $< --wildcards --strip-components=1 "*/$@"

proposal.rst: proposal.rst.mako enmako.py
	python3 enmako.py $< -o $@
	python3 -m doctest $@

proposal.html: proposal.rst style.css rst2html.py
	python2 ./rst2html.py --stylesheet=style.css $< $@

# proposal.tex: proposal.rst
# 	rst2latex.py $< $@

proposal.pdf: proposal.rst # proposal.tex
	# pdflatex $<
	rst2pdf $< $@
