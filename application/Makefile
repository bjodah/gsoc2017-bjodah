proposal.html: proposal.rst
	rst2html.py $< $@

proposal.rst: proposal.rst.mako
	mako-render $< >$@
	python3 -m doctest $@
