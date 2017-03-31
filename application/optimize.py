# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)

from sympy import log, Add, exp, Max, Min, Wild, Pow
from sympy.codegen.cfunctions import log1p, log2, exp2


class Optimization(object):
    def __init__(self, cost_function=None, priority=1):
        self.cost_function = cost_function
        self.priority=priority


class ReplaceOptim(Optimization):
    """ See :meth:`sympy.core.basic.Basic.replace` """
    def __init__(self, query, value, **kwargs):
        super(ReplaceOptim, self).__init__(**kwargs)
        self.query = query
        self.value = value

    def __call__(self, expr):
        return expr.replace(self.query, self.value)


def optimize(expr, optimizations, n_passes=1):
    """ Apply optimizations to an expression """
    for _ in range(n_passes):
        for optim in sorted(optimizations, key=lambda opt: opt.priority, reverse=True):
            new_expr = optim(expr)
            if optim.cost_function is None:
                expr = new_expr
            else:
                before, after = map(optim.cost_function, (expr, new_expr))
                if before > after:
                    expr = new_expr
    return expr


base2_exp_opt = ReplaceOptim(
    lambda p: (isinstance(p, Pow)
               and p.base == 2),
    lambda p: exp2(p.exp)
)

w = Wild('w')
v = Wild('v')
base2_log_opt = ReplaceOptim(v*log(w)/log(2), v*log2(w),
                             cost_function=lambda expr: expr.count(log) + expr.count(log2))

optims_base2 = (base2_exp_opt, base2_log_opt)

logsumexp_2terms_opt = ReplaceOptim(
    lambda l: (isinstance(l, log)
               and isinstance(l.args[0], Add)
               and len(l.args[0].args) == 2
               and all(isinstance(t, exp) for t in l.args[0].args)),
    lambda l: (
        Max(*[e.args[0] for e in l.args[0].args]) +
        log1p(exp(Min(*[e.args[0] for e in l.args[0].args])))
    )
)
