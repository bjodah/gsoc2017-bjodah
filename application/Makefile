style.css: ../.binaries/cskeeters-rst2html-style.tar.bz2
	tar xjf $< --wildcards --strip-components=1 "*/$@"

proposal.html: proposal.rst style.css
	rst2html.py --stylesheet=style.css $< $@

proposal.rst: proposal.rst.mako enmako.py
	python3 enmako.py $< -o $@
	python3 -m doctest $@
