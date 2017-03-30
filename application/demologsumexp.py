from functools import reduce
from operator import add
from sympy import log, exp, Function


def logsumexp_naive(args):
    return log(reduce(add, map(exp, args)))


class logsumexp(Function):
    def _eval_rewrite_as_log(self, expr):
        return logsumexp_naive(expr.args)

    def _eval_rewrite_as_CodeBlock(self, expr):
        pass
