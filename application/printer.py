# -*- coding: utf-8 -*-
from __future__ import (absolute_import, division, print_function)
from math import ceil, log10
from functools import wraps
import numpy as np
from sympy.core import Integer, S
from sympy.printing.ccode import C99CodePrinter, known_functions_C99
from sympy.printing.cxxcode import CXX11CodePrinter
from sympy.printing.precedence import precedence
from symast import Pointer, Variable

_float_lim = ceil(-log10(np.finfo(np.float32).eps))
_double_lim = ceil(-log10(np.finfo(np.float64).eps))
_long_double_lim = ceil(-log10(np.finfo(np.float128).eps))

class requires(object):
    def __init__(self, headers=None, libraries=None):
        self._headers = headers or set()
        self._libraries = libraries or set()

    def __call__(self, meth):
        @wraps(meth)
        def _method_wrapper(self_, *args, **kwargs):
            self_.headers.update(self._headers)
            self_.libraries.update(self._libraries)
            return meth(self_, *args, **kwargs)
        return _method_wrapper


class MyCPrinter(C99CodePrinter):

    def __init__(self, *args, **kwargs):
        self.headers = set()
        self.libraries = set()
        super(MyCPrinter, self).__init__(*args, **kwargs)

    def _print_Type(self, expr):
        type_name, = expr.args
        if type_name in ('intc', 'integer'):
            return 'int'
        elif type_name == 'real':
            prec = self._settings.get('precision', 15)
            if prec <= _float_lim:
                return 'float'
            elif prec <= _double_lim:
                return 'double'
            elif prec <= _long_double_lim:
                return 'long double'
            else:
                raise NotImplementedError()
        elif type_name == 'bool':
            self.headers.add('stdbool.h')
            return 'bool'

    def _print_While(self, expr):
        condition, body = map(self._print, expr.args)
        return 'while ({condition}) {{\n{body}\n}}'.format(condition=condition, body=body)

    def _print_Scope(self, expr):
        arg, = expr.args
        return '{\n%s\n}' % self._print(arg)

    def _print_Declaration(self, expr):
        var, value = expr.args
        if isinstance(var, Pointer):
            result = '{vc}{t} *{pc} {s}{r}'.format(
                vc='const ' if var.value_const else '',
                t=self._print(var.type),
                s=self._print(var.symbol),
                pc=' const' if var.pointer_const else '',
                r=' restrict' if var.restrict else ''
            )
        elif isinstance(var, Variable):
            result = '{vc}{t} {s}'.format(
                vc='const ' if var.const else '',
                t=self._print(var.type),
                s=self._print(var.symbol)
            )
        else:
            raise NotImplementedError("Unknown type of var: %s" % type(var))
        if value is not None:
            result += ' = %s' % self._print(value)
        return '%s;' % result

    @requires('stdio.h')
    def _print_PrintStatement(self, expr):
        fmtstr, iterable = expr.args
        return 'printf("%s", %s);' % (fmtstr, ', '.join(map(self._print, iterable)))

    def _print_FunctionCall(self, expr):
        return '%s(%s)%s' % (expr.args[0], ', '.join(map(self._print, expr.args[1])),
                             ';' if expr.args[2] else '')

    def _print_FunctionPrototype(self, expr):
        return_type, name, input_types = expr.args
        return "%s %s(%s)" % tuple(map(self._print, (return_type, name)),
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

    @requires({'math.h'}, {'m'})
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

    def _print_PrinterSetting(self, expr):
        return str(self._settings[expr.args[0]])

    @requires({'stdbool.h'})
    def _print_BooleanTrue(self, expr):
        return 'true'

    @requires({'stdbool.h'})
    def _print_BooleanFalse(self, expr):
        return 'false'

    def _print_Variable(self, expr):
        return self._print(expr.symbol)

    def _print_Pointer(self, expr):
        return self._print(expr.symbol)

    def _print_IndexedBase(self, expr):
        return self._print(Pointer(expr.label))


def my_ccode(expr, **kwargs):
    return MyCPrinter(**kwargs).doprint(expr)


class BoostMPCXXPrinter(CXX11CodePrinter):

    _default_settings = dict(CXX11CodePrinter._default_settings, mp_int=False)

    def __init__(self, *args, **kwargs):
        self.headers = set()
        self.libraries = set()
        self.using = set()
        super(BoostMPCXXPrinter, self).__init__(*args, **kwargs)

    def _print_Integer(self, expr):
        if self._settings.get('mp_int'):
            self.using.add('boost::multiprecision::cpp_int')
            return 'cpp_int("%s")' % hex(expr)
        return super(BoostMPCXXPrinter, self)._print_Integer(self, expr)

    @requires({'boost/multiprecision/cpp_int.hpp'})
    def _print_Rational(self, expr):
        if self._settings.get('mp_int'):
            self.using.add('boost::multiprecision::cpp_rational')
            return 'cpp_rational(%s, %s)' % tuple(map(self._print, map(Integer, (expr.p, expr.q))))
        else:
            return super(BoostMPCXXPrinter, self)._print_Rational(self, expr)


def boost_cxx_code(expr, **kwargs):
    return BoostMPCXXPrinter(settings=kwargs).doprint(expr)
