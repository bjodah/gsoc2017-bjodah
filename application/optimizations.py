# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)
from itertools import filterfalse, tee, chain

from sympy import log, Add, exp, Max, Min, Wild, Pow, expand_log, Pow
from sympy.codegen.cfunctions import log1p, log2, exp2, expm1

# TODO: cost_function should be called on each replace-occurance, not on resulting expression


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


def optimize(expr, optimizations):
    """ Apply optimizations to an expression """
    for optim in sorted(optimizations, key=lambda opt: opt.priority, reverse=True):
        new_expr = optim(expr)
        if optim.cost_function is None:
            expr = new_expr
        else:
            before, after = map(optim.cost_function, (expr, new_expr))
            if before > after:
                expr = new_expr
    return expr


exp2_opt = ReplaceOptim(
    lambda p: (isinstance(p, Pow)
               and p.base == 2),
    lambda p: exp2(p.exp)
)

u = Wild('u', properties=[lambda x: x.is_Symbol])
v = Wild('v')
w = Wild('w')


log2_opt = ReplaceOptim(v*log(w)/log(2), v*log2(w), cost_function=lambda expr: expr.count(
    lambda e: (
        (isinstance(e, Pow) and e.exp.is_negative)
        or (isinstance(e, (log, log2)) and not e.args[0].is_number))
    )
)

log2const_opt = ReplaceOptim(log(2)*log2(w), log(w))

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


def _partition(predicate, iterable):
    iter_a, iter_b = tee(iterable)
    return tuple(filter(predicate, iter_a)), tuple(filterfalse(predicate, iter_b))


def _try_expm1(e):
    return e.factor().replace(exp(w) - 1, expm1(w))


def _expm1_value(e):
    def isnum(arg):
        return arg.is_number
    numbers, non_num = _partition(lambda arg: arg.is_number, e.args)
    non_num_exp, non_num_other = _partition(lambda arg: arg.has(exp), non_num)
    numsum = sum(numbers)
    new_exp_terms, done = [], False
    for exp_term in non_num_exp:
        if done:
            new_exp_terms.append(exp_term)
        else:
            looking_at = exp_term + numsum
            attempt = _try_expm1(looking_at)
            if looking_at == attempt:
                new_exp_terms.append(exp_term)
            else:
                done = True
                new_exp_terms.append(attempt)
    if not done:
        new_exp_terms.append(numsum)
    return e.func(*chain(new_exp_terms, non_num_other))


expm1_opt = ReplaceOptim(lambda e: e.is_Add, _expm1_value)


log1p_opt = ReplaceOptim(
    lambda e: isinstance(e, log),
    lambda l: expand_log(l.replace(
        log, lambda arg: log(arg.factor())
    )).replace(log(u+1), log1p(u))
)

# Collections of optimizations:
optims_c99 = (expm1_opt, log1p_opt, exp2_opt, log2_opt, log2const_opt)
