proposal.html: proposal.rst
	rst2html.py $< $@

proposal.rst: proposal.rst.mako enmako.py
	python3 enmako.py $< -o $@
	python3 -m doctest $@
