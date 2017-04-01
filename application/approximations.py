# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

from itertools import product
from sympy import Add, Symbol

def _max_abs_combo(expr, bounds):
    bounds = {k: v for k, v in bounds.items() if expr.has(k)}
    keys = tuple(bounds.keys())
    max_seen = 0
    for vals in product(*bounds.values()):  # expensive, could be more intelligent.
        max_seen = max(max_seen, abs(expr.subs(dict(zip(keys, vals)))))
    return max_seen

def _approx_sum(add, bounds, reltol=1e-16):
    args_maxabs = [_max_abs_combo(arg, bounds) for arg in add.args]
    print(add.args)
    print(args_maxabs)
    maxabs_arg = max(*args_maxabs)
    lim = reltol*maxabs_arg
    return add.func(*[arg for arg, x in zip(add.args, args_maxabs) if x > lim])

def approx(expr, bounds):
    return expr.replace(lambda p: p.is_Add, lambda x: _approx_sum(x, bounds))
