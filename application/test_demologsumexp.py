# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

import sympy as sp
from demologsumexp import logsumexp


def test_logsumexp():
    symbs = x, y, z = sp.symbols('x y z')
    lse = logsumexp(symbs)
    assert lse.rewrite(sp.log) - sp.log(sp.exp(x) + sp.exp(y) + sp.exp(z)) == 0
