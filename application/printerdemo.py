from __future__ import (absolute_import, division, print_function)

from math import ceil, log10
import numpy as np
from sympy.core import S
from sympy.printing.ccode import C99CodePrinter, known_functions_C99
from sympy.printing.precedence import precedence

from sympy.core.basic import Basic
header_requirements = {
    'PrintStatement': 'stdio.h',
}

_float_lim = ceil(-log10(np.finfo(np.float32).eps))
_double_lim = ceil(-log10(np.finfo(np.float64).eps))
_long_double_lim = ceil(-log10(np.finfo(np.float128).eps))

class MyPrinter(C99CodePrinter):
    def _print_Type(self, expr):
        type_name, = expr.args
        if type_name in ('intc', 'integer'):
            type_name = 'int'
        if type_name == 'real':
            prec = self._settings.get('precision', 15)
            if prec <= _float_lim:
                type_name = 'float'
            elif prec <= _double_lim:
                type_name = 'double'
            elif prec <= _long_double_lim:
                type_name = 'long double'
            else:
                raise NotImplementedError()
        return type_name

    def _print_While(self, expr):
        condition, body = map(self._print, expr.args)
        return 'while ({condition}) {{\n{body}\n}}'.format(condition=condition, body=body)

    def _print_Scope(self, expr):
        arg, = expr.args
        return '{\n%s\n}' % self._print(arg)

    def _print_Declaration(self, expr):
        var, value = expr.args
        if isinstance(var, Pointer):
            result = '{vc}{t} * {s}{pc}{r}'.format(
                vc='const ' if var.value_const else '',
                t=self._print(var.type),
                s=self._print(var.symbol),
                pc=' const' if var.pointer_const else '',
                r=' restrict' if var.restrict else ''
            )
        elif not isinstance(var, Variable):
            var = Variable(var)
            result = '%s %s' % tuple(map(self._print, (var.type, var.symbol)))
        if value is not None:
            result += ' = %s' % self._print(value)
        return '%s;' % result

    def _print_PrintStatement(self, expr):
        fmtstr, iterable = expr.args
        return 'printf("%s", %s);' % (fmtstr, ', '.join(map(self._print, iterable)))

    def _print_FunctionPrototype(self, expr):
        return_type, name, input_types = expr.args
        return "%s %s(%s)" % (*map(self._print, (return_type, name)),
                              ', '.join(map(self._print, input_types)))

    def _print_FunctionDefinition(self, expr):
        return_type, name, inputs, body = expr.args
        substrings = [self._print(return_type), self._print(name), ', '.join(
            s[:-1] for s in map(self._print, inputs)), self._print(body)]
        return "%s %s(%s){\n%s\n}" % tuple(substrings)

    def _print_ReturnStatement(self, expr):
        arg, = expr.args
        return 'return %s;' % self._print(arg)

    def _get_precision_suffix(self):
        prec = self._settings.get('precision', 15)
        if prec <= _float_lim:
            suffix = 'f'
        elif prec <= _double_lim:
            suffix = ''
        elif prec <= _long_double_lim:
            suffix = 'l'
        else:
            raise NotImplementedError("Need a higher precision datatype.")
        return suffix

    def _print_math_func(self, expr):
        known = known_functions_C99[expr.__class__.__name__]
        if not isinstance(known, str):
            for cb, name in known:
                if cb(*expr.args):
                    known = name
                    break
            else:
                raise ValueError("No matching printer")

        return '{ns}{name}{suffix}({args})'.format(
            ns=self._ns,
            name=known,
            suffix=self._get_precision_suffix(),
            args=', '.join(map(self._print, expr.args))
        )

    def _print_sin(self, expr):
        return self._print_math_func(expr)

    def _print_cos(self, expr):
        return self._print_math_func(expr)

    def _print_Abs(self, expr):
        return self._print_math_func(expr)

    def _print_Pow(self, expr):
        if "Pow" in self.known_functions:
            return self._print_Function(expr)
        PREC = precedence(expr)
        suffix = self._get_precision_suffix()
        if expr.exp == -1:
            return '1.0%s/%s' % (suffix.upper(), self.parenthesize(expr.base, PREC))
        elif expr.exp == 0.5:
            return '%ssqrt%s(%s)' % (self._ns, suffix, self._print(expr.base))
        elif expr.exp == S.One/3 and self.standard != 'C89':
            return '%scbrt%s(%s)' % (self._ns, suffix, self._print(expr.base))
        else:
            return '%spow%s(%s, %s)' % (self._ns, suffix, self._print(expr.base),
                                   self._print(expr.exp))


class While(Basic):
    """
    Examples
    --------
    >>> from sympy import symbols, Gt, Abs
    >>> from sympy.codegen import Assignment
    >>> x, dx = symbols('x dx')
    >>> expr = 1 - x**2
    >>> whl = While(Gt(Abs(dx), 1e-9), [
    ...     Assignment(dx, -expr/expr.diff(x)),
    ...     AddAugmentedAssignment(x, dx)
    ... ])

    """
    nargs = 2


class Scope(Basic):
    nargs = 1


class PrintStatement(Basic):
    """ (formatstring, Tuple)"""
    nargs = 2


class Type(Basic):
    """ follows numpy naming, see https://docs.scipy.org/doc/numpy/user/basics.types.html

    Arguments
    ---------
    name : str
        Either an explicit type: intc, intp, int8, int16, int32, int64, uint8, uint16, uint32, uint64,
        float16, float32, float64, complex64, complex128.
        Or only kind (precision decided by code-printer): real, integer

    """
    allowed_names = tuple('intc intp int8 int16 int32 int64 uint8 uint16 uint32'.split() +
                          'uint64 float16 float32 float64 complex64 complex128'.split() +
                          'real integer'.split())
    __slots__ = []

    def __new__(cls, name):
        if isinstance(name, Type):
            return name
        if name not in cls.allowed_names:
            raise ValueError("Unknown type: %s" % name)
        return Basic.__new__(cls, name)


class Variable(Basic):
    """ name, type, constness """
    def __new__(cls, symbol, type_=None, const=False):
        if isinstance(symbol, Variable):
            return symbol
        if type_ is None:
            if symbol.is_integer:
                type_ = 'integer'
            else:
                type_ = 'real'
        return Basic.__new__(cls, symbol, Type(type_), const)

    @property
    def symbol(self):
        return self.args[0]

    @property
    def type(self):
        return self.args[1]

    @property
    def const(self):
        return self.args[2]

class Pointer(Basic):
    """ name, type, value_const, pointer_const, restrict"""
    def __new__(cls, symbol, type_=None, value_const=False, pointer_const=False, restrict=False):
        if type_ is None:
            if symbol.is_integer:
                type_ = Type('integer')
            else:
                type_ = Type('real')
        return Basic.__new__(cls, symbol, typ_, value_const, pointer_const, restrict)

    @property
    def symbol(self):
        return self.args[0]

    @property
    def type(self):
        return self.args[1]

    @property
    def value_const(self):
        return self.args[2]

    @property
    def pointer_const(self):
        return self.args[3]

    @property
    def restrict(self):
        return self.args[4]



class Declaration(Basic):
    def __new__(cls, variable, value=None):
        return Basic.__new__(cls, variable, value)


class FunctionDefinition(Basic):
    """ return_type, name, inputs, body """
    def __new__(cls, return_type, name, inputs, body):
        return Basic.__new__(cls, Type(return_type), name,
                             tuple(Declaration(inp) for inp in inputs), body)


class FunctionPrototype(Basic):
    """ return_type, name, input_types """
    @classmethod
    def from_FunctionDefinition(cls, func_def):
        return_type, name, inputs, body = func_def.args
        return cls(return_type, name, tuple(inp.type for inp in inputs))


class ReturnStatement(Basic):
    pass
