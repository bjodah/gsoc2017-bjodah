# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

from itertools import product
from sympy import Add, Symbol, sin, Abs
from optimizations import ReplaceOptim, Optimization

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


class ApproxOptim(ReplaceOptim):
    def __call__(self, expr, **kwargs):
        return expr.replace(self.query, lambda arg: self.value(arg, **kwargs))


sum_approx = ApproxOptim(lambda p: p.is_Add, _approx_sum)

# def approx(expr, bounds):
#     return expr.replace(lambda p: p.is_Add, lambda x: _approx_sum(x, bounds))


class TaylorApprox(ApproxOptim):
    def __init__(self, target, max_order=6, **kwargs):
        if target.nargs != {1}:
            raise NotImplementedError("Only univariate taylor expansions implemented")
        Optimization.__init__(self, **kwargs)
        self.max_order = max_order
        self.query = lambda e: isinstance(e, target) and len(e.args) == 1 and e.args[0].is_Symbol

    def value(self, expr, bounds, reltol, abstol):
        arg, = expr.args
        lo, hi = bounds[arg]
        x0 = (lo + hi)/2
        cheapest = None
        for n in range(self.max_order, 0, -1):
            ser = expr.series(arg, x0=x0, n=n).removeO()
            val_lo = ser.xreplace({arg: lo})
            val_hi = ser.xreplace({arg: hi})
            ref_lo = expr.xreplace({arg: lo})
            ref_hi = expr.xreplace({arg: hi})
            relerr_lo = abs((1 - ref_lo/val_lo).evalf())
            relerr_hi = abs((1 - ref_hi/val_hi).evalf())
            abserr_lo = abs((val_lo - ref_lo).evalf())
            abserr_hi = abs((val_hi - ref_hi).evalf())
            lo_ok = relerr_lo < reltol or abserr_lo < abstol
            hi_ok = relerr_hi < reltol or abserr_hi < abstol
            print(expr, n)
            print(relerr_lo, relerr_hi)
            print(abserr_lo, abserr_hi)
            print()
            if hi_ok and lo_ok:
                cheapest = ser
            else:
                break
        if cheapest is None:
            return expr
        else:
            return cheapest


sin_approx = TaylorApprox(sin)
