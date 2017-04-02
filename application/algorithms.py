from __future__ import (absolute_import, division, print_function)

from sympy import And, Gt, Lt, Abs, Dummy, oo, Tuple, Symbol, Function, Pow
from sympy.codegen.ast import Assignment, AddAugmentedAssignment, CodeBlock

from symast import (
    Declaration, PrintStatement, FunctionDefinition, While, Scope, ReturnStatement,
    Declaration, PrinterSetting, Variable, Pointer
)


def newton_raphson_algorithm(expr, wrt, atol=1e-12, delta=None, debug=False,
                             itermax=None, counter=None):
    """
    See https://en.wikipedia.org/wiki/Newton%27s_method
    """
    if delta is None:
        delta = Dummy()
        Wrapper = Scope
        name_d = 'delta'
    else:
        Wrapper = lambda x: x
        name_d = delta.name

    delta_expr = -expr/expr.diff(wrt)
    body = [Assignment(delta, delta_expr), AddAugmentedAssignment(wrt, delta)]
    if debug:
        prnt = PrintStatement(r"{0}=%12.5g {1}=%12.5g\n".format(wrt.name, name_d), Tuple(wrt, delta))
        body = [body[0], prnt] + body[1:]
    if isinstance(atol, float) and atol < 0:
        atol = -atol*10**-PrinterSetting('precision')
    req = Gt(Abs(delta), atol)
    declars = [Declaration(delta, oo)]
    if itermax is not None:
        counter = counter or Dummy(integer=True)
        declars.append(Declaration(counter, 0))
        body.append(AddAugmentedAssignment(counter, 1))
        req = And(req, Lt(counter, itermax))
    whl = While(req, CodeBlock(*body))
    blck = declars + [whl]
    return Wrapper(CodeBlock(*blck))


def _symbol_of(arg):
    if isinstance(arg, (Variable, Pointer)):
        return arg.symbol
    else:
        return arg

def newton_raphson_function(expr, wrt, args=None, func_name="newton", **kwargs):
    if args is None:
        args = (wrt,)
    pointer_subs = {p.symbol: Symbol('(*%s)' % p.symbol.name)
                    for p in args if isinstance(p, Pointer)}
    delta = kwargs.pop('delta', None)
    if delta is None:
        delta = Symbol('d_' + wrt.name)
        if expr.has(delta):
            delta = None  # will use Dummy
    algo = newton_raphson_algorithm(expr, wrt, delta=delta, **kwargs).xreplace(pointer_subs)
    if isinstance(algo, Scope):
        algo, = algo.args
    not_in_args = expr.free_symbols.difference(set(_symbol_of(arg) for arg in args))
    if not_in_args:
        raise ValueError("Missing symbols in args: %s" % ', '.join(map(str, not_in_args)))
    return FunctionDefinition("real", func_name, args, CodeBlock(algo, ReturnStatement(wrt)))
