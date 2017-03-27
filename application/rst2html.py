#!/usr/bin/python2

# $Id: rst2html.py 4564 2006-05-21 20:44:42Z wiemann $
# Author: David Goodger <goodger@python.org>
# Copyright: This module has been placed in the public domain.

"""
A minimal front end to the Docutils Publisher, producing HTML.
"""

try:
    import locale
    locale.setlocale(locale.LC_ALL, '')
except:
    pass

from docutils.core import publish_cmdline, default_description

# http://stackoverflow.com/questions/4716856/use-restructuredtext-for-pretty-source-code-listing/5061604#5061604
from docutils.parsers.rst import directives
import rst2pdf.pygments_code_block_directive
directives.register_directive(
    'code-block', rst2pdf.pygments_code_block_directive.code_block_directive)


description = ('Generates (X)HTML documents from standalone reStructuredText '
               'sources.  ' + default_description)

publish_cmdline(writer_name='html', description=description)
