#!/usr/bin/env python

# This file should work with both Python 2 & Python 3:
#
#    $ python2 -m pytest enmako.py
#    $ python3 -m pytest enmako.py

import io
import argh
from mako.lookup import TemplateLookup
from mako.template import Template
from mako.exceptions import text_error_template


def render_mako_template(source_template, variables):
    try:
        template_str = source_template.read()
    except:
        template_str = io.open(source_template, 'rt', encoding='utf-8').read()
    lookup = TemplateLookup(directories=['.'])
    try:
        rendered = Template(template_str, input_encoding='utf-8',
                            output_encoding='utf-8', lookup=lookup).render(**variables)
    except:
        print(text_error_template().render())
        raise
    return rendered


def test_render_mako_template_to():
    from io import BytesIO

    example = """hello
    % for number in range(maxnum):
    world ${number}
    % endfor
    """
    result = render_mako_template(BytesIO(example.encode('utf-8')), {'maxnum': 4})
    assert result.decode('utf-8') == """hello
    world 0
    world 1
    world 2
    world 3
    """


def enmako(template_path, gen_subsd_eval=None, shell_cmd_subs=None, json_subs=None, pickle_subs=None, outpath=None):
    """
    User provides a template file path, e.g. `index.html.mako`
    and either a python expression (gen_subsd_eval) which evaluates to a dict e.g. '{"title": "Welcome"}'
    or a shell command (shell_cmd_subs) which outputs lines of form: title=Welcome
    If outpath is not given, template_path will be stripped from trailing `.mako` (required in that case)

    Note: json does not support integer keys in dicts
    """
    if outpath == None:
        assert template_path.endswith('.mako')
        outpath = template_path[:-5]

    subsd = {}
    assert sum([0 if x==None else 1 for x in [gen_subsd_eval, shell_cmd_subs, json_subs, pickle_subs]]) <= 1

    if gen_subsd_eval:
        subsd = eval(gen_subsd_eval)
    if json_subs:
        import json
        subsd = json.load(open(json_subs, 'rt'))
    if pickle_subs:
        try:
            import cPickle as pickle
        except ImportError:
            import pickle
        subsd = pickle.load(open(pickle_subs, 'rt'))
    if shell_cmd_subs:
        import subprocess
        outp = subprocess.check_output(shell_cmd_subs.split())
        subsd = dict([x.split('=') for x in outp.split('\n')[:-1]])

    result = render_mako_template(template_path, subsd)
    open(outpath, 'wb').write(result)


def test_enmako():
    import tempfile
    import os
    import shutil
    tmpdir = tempfile.mkdtemp()

    try:
        src = os.path.join(tmpdir, 'source.txt')
        dest = os.path.join(tmpdir, 'destination.txt')
        open(src, 'wt').write("""word: ${'foo' if x > 3 else 'bar'}""")

        enmako(src, '{"x": 2}', outpath=dest)
        assert open(dest, 'rt').read() == "word: bar"

        enmako(src, '{"x": 5}', outpath=dest)
        assert open(dest, 'rt').read() == "word: foo"
    finally:
        shutil.rmtree(tmpdir)


if __name__ == '__main__':
    argh.dispatch_command(enmako)
