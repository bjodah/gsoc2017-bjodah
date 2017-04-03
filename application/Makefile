.PHONY: all

all: proposal.html proposal.pdf

style.css: ../.binaries/cskeeters-rst2html-style.tar.bz2
	tar xjmf $< --wildcards --strip-components=1 "*/$@"

proposal.rst: proposal.rst.mako enmako.py logsum.out pow_num.out *.py
	python3 enmako.py $< -o $@
	python3 -m doctest -f $@

proposal.rst: proposal.rst.mako enmako.py logsum.out pow_num.out *.py
	python3 enmako.py $< -o $@
	python3 -m doctest -f $@

proposal_pdf.rst: proposal.rst.mako enmako.py logsum.out pow_num.out *.py
	python3 enmako.py -g "dict(for_pdf=True)" $< -o $@
	python3 -m doctest -f $@

proposal.html: proposal.rst style.css rst2html.py
	python2 ./rst2html.py --stylesheet=style.css $< $@

proposal.tex: proposal_pdf.rst
	rst2latex.py $< $@

proposal.pdf: proposal.tex
	pdflatex $<

logsum: logsum.c
	$(CC) -Wall -Wextra -Werror -o $@ $< -lm

logsum.out: logsum
	./$< >$@

pow_num.out: pow_num.sh
	./$< >$@
