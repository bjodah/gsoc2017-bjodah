<%doc> -*- mode: rst; eval: (auto-fill-mode); eval: (flyspell-mode) -*- </%doc>
.. ${'{0} eval: (read-only-mode) {0}'.format('-*-')}

Improved code-generation facilities
===================================

% if for_pdf is UNDEFINED:
.. contents::
% endif

About me
--------

+---------------+----------------------------------------------------------------+
|Name           |Björn Dahlgren                                                  |
+---------------+----------------------------------------------------------------+
|Email          |`bjodah@gmail.com <bjodah@gmail.com>`_, `bda@kth.se             |
|               |<bda@kth.se>`_                                                  |
+---------------+----------------------------------------------------------------+
|University     |`KTH Royal Institute of Technology <http://www.kth.se/en>`_,    |
|               |Stockholm, Sweden                                               |
+---------------+----------------------------------------------------------------+
|Program        |PhD-student, project: Modelling interfacial radiation chemistry |
+---------------+----------------------------------------------------------------+
|Blog           |`<https://bjodah.github.io>`_                                   |
+---------------+----------------------------------------------------------------+
|Github profile |`<https://www.github.com/bjodah>`_                              |
+---------------+----------------------------------------------------------------+
|Time-zone      |UTC+01:00                                                       |
+---------------+----------------------------------------------------------------+
|Phone          |+46736366892                                                    |
+---------------+----------------------------------------------------------------+

Background
~~~~~~~~~~
I am a PhD student in my final year. I have a MSc in Chemical Science and
Engineering which included courses in numerical methods and scientific
programming. I am proficient with Python/C/C++/Fortran and have a
general interest in scientific computing. My preferred development
environment includes git and Emacs under Ubuntu (GNU/Linux).

Earlier contributions
~~~~~~~~~~~~~~~~~~~~~
I have been an active contributor to SymPy since about 3 years with
`35 pull-requests <https://github.com/sympy/sympy/pulls/bjodah>`_
(of which 25 have been merged) for SymPy (*e.g.* a `C++ code printer
<https://github.com/sympy/sympy/pull/11637>`_), 
`a handful <https://github.com/sympy/sympy_benchmarks/pulls/bjodah>`_
for ``sympy_benchmarks``,
`one <https://github.com/symengine/symengine/pull/1075>`_
for SymEngine and `a few
<https://github.com/symengine/symengine.py/pulls/bjodah>`_
for the Python wrappers of SymEngine. I'm also the author of two
open-source python libraries with a general audience which use SymPy 
as their primary backend for solving `initial value problems
<https://en.wikipedia.org/wiki/Initial_value_problem>`_ (IVPs) for 
`systems of ordinary differential equations (ODE systems)
<https://en.wikipedia.org/wiki/Ordinary_differential_equation#System_of_ODEs>`_
and `systems of nonlinear equations
<https://en.wikipedia.org/wiki/Gradient_descent#Solution_of_a_non-linear_system>`_
respectively:

- `pyodesys`_: Solving IVPs for systems of ODEs
- `pyneqsys`_: Solving (possibly overdetermined) noninear systems by optimization.


I have been using SymPy to do code-generation in various domain
specific projects: 

- `ChemPy <https://github.com/bjodah/chempy>`_: solving problems in
  chemical kinetics and equilibria using `pyodesys`_ and `pyneqsys`_
  respectively.
- `mdiosvcor <https://github.com/bjodah/mdiosvcor>`_ - Molecular
  Dynamics Ion Solvation Correction terms (using a `patched version`_ of
  ``sympy.utilities.autowrap``)
- `fastinverse <https://github.com/bjodah/fastinverse>`_: using
  `pycodeexport <https://github.com/bjodah/pycodeexport>`_ (which uses
  SymPy) and `pycompilation <https://github.com/bjodah/pycompilation>`_
- `cInterpol <https://github.com/bjodah/cinterpol>`_: library for fast
  polynomial interpolation where the formulae are derived
  using ``sympy.solve`` during the code-generation phase.

.. _pyodesys: https://github.com/bjodah/pyodesys
.. _pyneqsys: https://github.com/bjodah/pyneqsys
.. _patched version: https://github.com/bjodah/mdiosvcor/blob/master/mdiosvcor/mod_autowrap.py

Time commitment
~~~~~~~~~~~~~~~
If accepted, I will have no other commitments, meaning that I will be
avaiable 40 h/week during the program. Any shorter vaccation
will, in addition to being coordinated with the mentor, be compensated
in advance e.g. by working 50 h/week during 4 weeks leading up to 1
week of vaccation. I will hopefully spend one week at the SciPy 2017
conference, in which case I will help out teaching a tutorial on
using ``SymPy``'s code-generation facilities, and participate in
the code-sprints. Time spent at the conference will therefore go
directly into the project.

Synopsis
--------
The code-generation facilities in SymPy are already in active use in
the research community. There are, however, still many exciting
opportunities for further improvements. As a CAS, SymPy has access to
far more information than a compiler processing typical source code in
languages such C/C++/Fortran. SymPy uses arbitrary precision
arithmetics which means that the size and precision of numbers
represented are only limited by the amount of memory the computer has
accesess too. However, operations with arbitrary precision are
inherently slow, which is why high performance code relies on
`floating-point arithmetic
<https://en.wikipedia.org/wiki/Floating-point_arithmetic>`_ (which has
`dedicated hardwarde
<https://en.wikipedia.org/wiki/Floating-point_unit>`_ in modern CPUs).
Therefore, any code generation for a programming language which maps
mathematical expressions to finite precision floating point
instructions, would benefit greatly if that code-generation was made
in such a way to minimize `loss of significance
<https://en.wikipedia.org/wiki/Loss_of_significance>`_, risk of
under-/overflow *etc.*

The source code for this docuemnt, all the examples and some
additional jupyter notebooks can be found at
`<https://github.com/bjodah/gsoc2017-bjodah>`_ (with a mirror at:
`<https://gitlab.com/bjodah/gsoc2017-bjodah>`_). Note that there are
also some unit tests for the classes and functions proposed here.

Improving ``sympy.codegen`` with more high-level abstractions
-------------------------------------------------------------
SymPy has facilities for generating code in other programming
languages (with a focus on statically typed and compiled languages
which offer considerable performance advantages compared to pure
Python).

Current status
~~~~~~~~~~~~~~
The current code-generation facilities are spread out over:

- ``CodePrinter`` and its subclasses in the ``sympy.printing``
  subpackage.
- ``CodeGen`` and its related classes in ``sympy.utilities.codegen``.
- Types for abstract syntax tree (AST) generation in
  ``sympy.codegen.ast`` and related langauge specific types in
  ``sympy.codegen.cfunctions`` and ``sympy.codegen.ffunctions`` (for C-
  and Fortran-functions respectively).

Ideally the ``CodePrinter`` subclasses should only deal with
expressing the AST types as valid code in their respective languages.
Any manipulation of the AST—such as re-ordering or transforming
nodes—should preferably be performed by other classes prior to
reaching the printers.

Currently the code printers in the language specific modules under
``sympy.printing`` are geared toward generating inline expressions,
*e.g.*:

.. code:: python

   >>> import sympy as sp
   >>> x = sp.Symbol('x')
   >>> pw1 = sp.Piecewise((x, sp.Lt(x, 1)), (x**2, True))
   >>> print(sp.ccode(pw1))
   ((x < 1) ? (
      x
   )
   : (
      pow(x, 2)
   ))


this works because C has a ternary operator, however, for Fortran
earlier than Fortran 95 there is no ternary operator. The code printer
base-class has a work-around implemented for this: when we give the
keyword argument ``assign_to``, then the code printer can generate an
assignment statement instead of an expression, *e.g.*:

.. code:: python

   >>> y = sp.Symbol('y')
   >>> print(sp.fcode(pw1, assign_to=y))
         if (x < 1) then
            y = x
         else
            y = x**2
         end if

this in itself not a problem, but the way it is currently implemented,
is by handling ``Piecewise`` as a special case in the printing of
``Assignment``. This approach fails when we want to print nested
statements (*e.g.* a loop with a conditional break).


Proposed improvements
~~~~~~~~~~~~~~~~~~~~~
In ``sympy.codegen.ast`` there are building blocks for representing an
abstract syntax tree. This module should be extended by adding more
node types. 

There is a need to represent types of variables in the AST. There is
also a need to express variable declarations (which would contain type
information as well as the variable name). C in particular (and even
Fortran when interfaced with C) also need to make the distinction
between variables passed by value or reference (where the latter
require a ``Pointer`` node class). In order to make the type choice as
generic as possible we could introduce generic types, *e.g.* ``real``,
which would get its actual precision determined by the time of
printing by a printer setting (*cf.* ``float``, ``double`` & ``long  
double``).

When the proposed types are in place (see e.g. `symast.py
<https://github.com/bjodah/gsoc2017-bjodah/blob/master/application/symast.py>`_
from the supplementary material repository), we could introduce a new
module: ``sympy.codegen.algorithms``, containing common algorithms
which are often rewritten today in every 
new project. Let us consider the Newton-Rhapson method as a
case study (see `algorithms.py
<https://github.com/bjodah/gsoc2017-bjodah/blob/master/application/algorithms.py>`_):

.. code:: python

   >>> from algorithms import newton_raphson_algorithm
   >>> from printer import my_ccode
   >>> x, k, dx, atol = sp.symbols('x k dx atol')
   >>> expr = sp.cos(k*x) - x**3
   >>> algo = newton_raphson_algorithm(expr, x, atol, dx)
   >>> print(my_ccode(algo))
   double dx = INFINITY;
   while (fabs(dx) > atol) {
      dx = (pow(x, 3) - cos(k*x))/(-k*sin(k*x) - 3*pow(x, 2));
      x += dx;
   }

This and related algorithms could be of great value for users writing
applied code. It is important to realize that users do not always
control the signature of their implemented functions when those serve
as callbacks for use with external libraries. Some arguments 
might be passed by reference, again we see the need for AST node types
with rich type information (``Pointer`` in this case):

.. code:: python

   >>> from algorithms import newton_raphson_function as newton_func
   >>> from symast import Pointer
   >>> kp = Pointer(k, value_const=True, pointer_const=True)
   >>> print(my_ccode(newton_func(expr, x, (x, kp))))
   double newton(double x, const double * const k){
      double d_x = INFINITY;
      while (fabs(d_x) > 1.0e-12) {
         d_x = (pow(x, 3) - cos((*k)*x))/(-(*k)*sin((*k)*x) - 3*pow(x, 2));
         x += d_x;
      }
      return x;
   }

In the final implementation we may want to declare a ``const k_ = *k``
at function entry for better brevity.

Currently the printers do not track what methods have been called.
It would be useful if at least C-code printers kept a per instance set of
headers and libraries used, *e.g.*:

.. code:: python

   >>> from printer import MyCPrinter
   >>> instance = MyCPrinter()
   >>> instance.doprint(x/(x+sp.pi))
   'x/(x + M_PI)'
   >>> print(instance.headers, instance.libraries)
   set() set()
   >>> instance.doprint(sp.Abs(x/(x+sp.pi)))
   'fabs(x/(x + M_PI))'
   >>> print(instance.headers, instance.libraries)
   {'math.h'} {'m'}

this would allow users to subclass the printers with methods using
functions from external libraries. An example of what this may look
like can be seen `here
<https://github.com/bjodah/gsoc2017-bjodah/blob/master/application/printer.py>`_.

Better support for different types
----------------------------------
The module ``sympy.utilities.codegen`` currently offers the most
complete functionality to generate complete function
implementations. Its design, however, does not lend itself to easy
extension through sub-classing, *e.g.* the ``CodeGen.routine`` method
does not use the visitor pattern, instead it handles different types
through ``if``-statements which makes it hard to use with expressions
containing user-defined classes. Also the ``CCodeGen`` class
hard-codes (though in a method which may be overloaded) what headers
to include. The notion of types in ``sympy.utilities.codegen`` is also
somewhat confusing: *e.g.* there is no easy way to use the binary32
IEEE 754 floating point data type. The shortcoming in ``CodeGen``
stems from the fact that the printers have not provided the necessary
information (*e.g.* what headers have been used, what precision is
targeted, *etc.*).

A popular feature in SymPy is common subexpresison elimination (CSE),
currently the code printers are not catered to deal with these in an
optimal way. Consider e.g.: 

.. code:: python

   >>> from sympy import exp
   >>> pw2 = sp.Piecewise((2/(x + 1), sp.Lt(x, 1)), (exp(1-x), True))
   >>> cses, (new_expr,) = sp.cse(pw1 + pw2)
   >>> print(cses)
   [(x0, x < 1)]

The code printers do not handle booleans properly, this should be
improved so that codeblocks can be generated where cse variables have
their type deteremined automatically:

.. code:: python

   >>> from symast import assign_cse
   >>> code_printer = MyCPrinter()
   >>> print(code_printer.doprint(assign_cse(y, pw1 + pw2)))
   {
      const bool x0 = x < 1;
      y = ((x0) ? (
         x
      )
      : (
         pow(x, 2)
      )) + ((x0) ? (
         2/(x + 1)
      )
      : (
         exp(-x + 1)
      ));
   }
   >>> print(code_printer.headers)
   {'stdbool.h'}
   
when using ``C++11`` as target language we may choose to declare CSE
variables ``auto`` which leaves type-deduction to the compiler. Note
that the ``assign_cse`` prototype addresses a large part of gh-11038_.
It may well be that we will let some AST nodes perform CSE
automatically by default.

Finite precision arithmetics
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Currently there is only rudimentary facilities to deal with precision
in the code printers (the current implementation essentially only deals
with the number of decimals printed for number constants). But even
for number literals consistency is lacking (see e.g. gh-11803_ where
``long double`` literals are used by default).

The new ``sympy.codegen.algorithms`` modeule should leave the decision
of required precision to the user, revisiting the
``newton_raphson_algorithm`` example:

.. code:: python

   >>> print(my_ccode(algo, settings={'precision': 7}))
   float dx = INFINITY;
   while (fabsf(dx) > atol) {
      dx = (powf(x, 3) - cosf(k*x))/(-k*sinf(k*x) - 3*powf(x, 2));
      x += dx;
   }

Note how our lowered precision affected what functions that got used
(``fabsf``, ``powf``, ``cosf`` & ``sinf``), something the current
printers cannot do. It should be noted that
``C++`` already allows the user to write type-generic code, but still
today not all platforms have ``C++`` compilers, and for those platforms the
convenience of generating ``C`` code based on precision can greatly reduce the
manual labor of rewriting the expressions.

When we generate different code depending on a printer-setting it is
beneficial if that information is available to the nodes in the AST during
printing. For example, the magnitude for the choice of ``atol`` inherently
depends on the machine epsilon for the underlying data type. By
introducing a special node type which reads settings, we can solve
this in a quite elegant manner:

.. code:: python

   >>> from symast import PrinterSetting
   >>> prec = PrinterSetting('precision')
   >>> algo2 = newton_raphson_algorithm(expr, x, atol=10**(1-prec), delta=dx)
   >>> print(my_ccode(algo2, settings={'precision': 15}))
   double dx = INFINITY;
   while (fabs(dx) > pow(10, 1 - 15)) {
      dx = (pow(x, 3) - cos(k*x))/(-k*sin(k*x) - 3*pow(x, 2));
      x += dx;
   }

<%!
    from subprocess import getoutput
    gcc_version = getoutput('gcc --version').split('\n')[0].split()[-2]
%>

if you are worried about the ``pow(10, 1 - 15)`` call, don't be, let
us look at the assembly generated by gcc ${gcc_version}:

.. code:: bash

   ${'   '.join(open("pow_num.sh").readlines())}

running the above script:

.. code:: bash
          
   $ ./pow_num.sh
   ${'   '.join(open("pow_num.out").readlines())}

which means that the generated assembly was identical (even with no
optimizations turned on).

Arbitrary precision
~~~~~~~~~~~~~~~~~~~
Today `boost <http://www.boost.org>`_ offer classes to work with
multiprecision numbers in C++. A new C++ code printer class for
working with these classes should be provided
(``cpp_dec_float_50`` *etc.*). Currently the
code printers in SymPy assumes that the user is mainly interested in
floating point arithmetics. Consider *e.g.*:

.. code:: python

   >>> r = sp.Rational(10**20 + 1, 10**20)
   >>> m = sp.Symbol('m', integer=True)
   >>> sp.ccode(r - m)
   '-m + 100000000000000000001.0L/100000000000000000000.0L'

if ``m == 1`` the above expression will be rounded to zero, a boost
printer could have a setting enabling printing of ``Rational`` as
``cpp_rational``:

.. code:: python

   >>> from printer import BoostMPCXXPrinter
   >>> mp_printer = BoostMPCXXPrinter(settings={'mp_int': True})
   >>> print(mp_printer.doprint(r-m).replace(', ', ',\n '))
   -m + cpp_rational(cpp_int("0x56bc75e2d63100001"),
    cpp_int("0x56bc75e2d63100000"))
   >>> print(mp_printer.headers)
   {'boost/multiprecision/cpp_int.hpp'}
   >>> for use in sorted(mp_printer.using):
   ...     print(use)
   ...
   boost::multiprecision::cpp_int
   boost::multiprecision::cpp_rational


note how we used a per instance set ``using`` to keep track of what
``using`` statements the generated code relies on. Since SymPy already
offer multiprecision support, the common use case for generating
multiprecision code would be to calculate reference solutions and
compare those results with code generated with lower precision (some
numerical C++ libraries are type-generic and this is where this
feature becomes valuable).

Optimizations
-------------
Prior to reaching the ``CodePrinters`` the user may want to apply
transformations to their expressions. Optimization here is
context dependent, and may refer to higher precision, or better
performance (often at the cost of significance loss).

Sometimes performance and precision `optimizations
<https://github.com/bjodah/gsoc2017-bjodah/blob/master/application/optimizations.py>`_
are not mutually exclusive, *e.g.*:

.. code:: python

   >>> from sympy import log
   >>> expr = 2**x + log(x)/log(2)
   >>> from optimizations import optimize, optims_c99
   >>> optimize(expr, optims_c99)
   exp2(x) + log2(x)

here our prototype C-code printer used the ``exp2`` and ``log2`` functions from
the C99 standard, these functions offer slightly better performance
since the floating point numbers use base 2.

Some functions are specifically designed to avoid catastrophic
cancellation, *e.g.*: 

.. code:: python

   >>> optimize((2*exp(x) - 2)*(3*exp(y) - 3), optims_c99)
   6*expm1(x)*expm1(y)

the prototype printer rewrote the expression using `expm1
<http://en.cppreference.com/w/c/numeric/math/expm1>`_ which conserves
significance when ``x`` is close to zero.

Consider the following code:

.. code:: python

   >>> x, y = sp.symbols('x y')
   >>> expr = exp(x) + exp(y)
   >>> sp.ccode(expr)
   'exp(x) + exp(y)'

If we have *a priori* knowledge about the magnitudes of the variables we
could generate code that is more efficient and gives the same results:

.. code:: python

   >>> from approximations import sum_approx
   >>> kwargs = dict(bounds={x: (0, sp.oo), y: (-sp.oo, -50)}, reltol=1e-16)
   >>> optimize(expr, [sum_approx], **kwargs)
   exp(x)

above a smart code printer could have provided ``reltol``
corresponding to the targeted precision (*e.g.* machine epsilon values
of `IEEE 754 <http://grouper.ieee.org/groups/754/>`_ binary64 and binary32.

Even when knowledge about bounds for variables are lacking there are
still things we can do. Expressions can sometimes be rewritten in
order to avoid underflow and overflow, consider *e.g.*:

.. code:: python

   >>> logsum = log(exp(x) + exp(y))
   >>> str(logsum.subs({x: 800, y: -800}).evalf()).rstrip('0')
   '800.'

there are a few hundred of zeros before the second term makes
its presence known. The C code generated for the above expression
looks like this:

.. code:: python

   >>> print(sp.ccode(logsum))
   log(exp(x) + exp(y))

compiling that expression as a C program with values 800 and -800 for
x and y respectively:

.. code:: C

   ${'   '.join(open("logsum.c").readlines())}


and running that program:

.. code:: bash

   $ ./logsum
   ${'   '.join(open("logsum.out").readlines())}

illustrates the dangers of finite precision arithmetics.
The same problem arises when using ``lambdify``:

.. code:: python

   >>> cb = sp.lambdify([x, y], logsum)
   >>> cb(800, -800)
   inf

In this particular case, the expression could be rewritten
as:

.. code:: python

   >>> from sympy import Min, Max, log
   >>> logsum2 = log(1 + exp(Min(x, y))) + Max(x, y)
   >>> cb2 = sp.lambdify([x, y], logsum2)
   >>> cb2(800, -800)
   800.0

actually that last expression should be written using ``log1p``:

.. code:: python

   >>> from sympy.codegen.cfunctions import log1p
   >>> logsum3 = log1p(exp(Min(x, y))) + Max(x, y)
   >>> cb3 = sp.lambdify([x, y], logsum3)
   >>> print('%.5e' % cb3(0, -99))
   1.01122e-43
   >>> print('%.5e' % cb2(0, -99))
   0.00000e+00
   >>> print('%.5e' % logsum.subs({x: 0, y: -99}).n(50))
   1.01122e-43

here we did the rewriting manually. What we need however are rules for
transforming subexpressions:

.. code:: python

   >>> expr = (1 + x)/(2 + 3*log(exp(x) + exp(y)))
   >>> from optimizations import logsumexp_2terms_opt
   >>> optimize(expr, [logsumexp_2terms_opt])
   (x + 1)/(3*log1p(exp(Min(x, y))) + 3*Max(x, y) + 2)

What is important to realize here is that a good implementation
contains a step where we identify the biggest number. Using ``Min``
and ``Max`` is not practical when the number of arguments is much
larger than 2. We need an algorithm:

.. code:: python

   >>> from demologsumexp import logsumexp
   >>> lse = logsumexp((x, y))
   >>> lse.rewrite(log)
   log(exp(x) + exp(y))
   >>> print(my_ccode(logsumexp.as_FunctionDefinition()))
   double logsumexp(double * x, int n){
      sympy_quicksort(x, n);
      int i = 0;
      double s = 0.0;
      while (i < n - 1) {
         s += exp(x[i]);
         i += 1;
      }
      return log1p(s) + x[n - 1];
   }

Sorting the array may be too pedantic in this case (although it makes
the summation more accurate). But when needed, sorting and
partitioning of arrays is something that different languages provide
different level of existing infrastructure for. In ``C++`` such
functions exist in the standard library, whereas in ``C`` there are
non. Here SymPy could provide a support library with templates.

In many algorithms (especially iterative ones), a computationally
cheaper approximation of an expression often works just as well, but
offers an opportunity for faster convergence saving both time and
energy.

A very common situtation in numerical codes is that the majority of
CPU cycles are spent solving linear systems of equations. For large
systems direct methods (*e.g.* LU decomposition) becomes prohibitively
expensive due to cubic algorithm complexity. The remedy is to rely on
iterative methods (*e.g.* GMRES), but these require good
pre-conditioners (unless the problem is very diagonally
dominant). A good pre-conditioner can be constructed from an
approximation of the inverse of the matrix describing the linear system.

A potentially very interesting idea would be to generate a
symbolic approximation of *e.g.* the LU decomposition of a matrix, and
when that approximate LU decomposition is sparse (in general, a sparse
matrix has a dense LU decomposition due to fill-in), the
approximation would then provide a tailored pre-conditioner
(based on assumptions about variable magnitudes).

Writing a pre-conditioner factory and evaluating it would be too big
of an undertaking during the program. However, providing the necessary
code-generation utilities (a symbolic version of incomplete
LU-decomposition) could provide a good design target for the
functions which are to be made finite-precision-aware.

Various related improvements
----------------------------
In case of the above projects turning out to be under-scoped, related
work is to extend the capabilities of ``lambdify``, particularly when
``SymEngine`` is used as a backend. In particular I'd like to finish:

- `symengine.py #112 <https://github.com/symengine/symengine.py/pull/112>`_: ``Lambdify``
  in SymEngine should work for heterogeneous input and without
  performance loss (still work to be done).


Timeline
--------
Below is a proposed schedule for the program.

Before GSoC 2017
~~~~~~~~~~~~~~~~
Since I have the privelige of being a prior contributor to the project
I am already familiar with the code-base and the parties interested in
code-generation in SymPy. I will therefore use the time during the
spring to general design (big picture structuring, API design) and
reading up on the details of finite precision arithmetics:

- `Higham, Accuracy and stability of numerical algorithms
  <https://books.google.se/books/about/Accuracy_and_Stability_of_Numerical_Algo.html?id=7J52J4GrsJkC&printsec=frontcover>`_,
  Chapter 27 in particular (and references therein).
- IEEE's `recommended reading <http://grouper.ieee.org/groups/754/>`_
  for the 754 standard.


Phase I, 2017-05-30 – 2017-06-30
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
This phase will mainly consist of incremental additions and
improvements to existing infrastructure in SymPy.

- Week 1:

  - Add new types to ``sympy.codegen.ast`` related to precision,
    e.g. ``Type`` ('float64', 'float32', *etc.*), ``Variable`` (type,
    name & constness), ``Declaration`` (wrapping ``Variable``).
  - New print methods in ``C99CodePrinter`` and ``FCodePrinter`` for printing
    ``Type`` & ``Declaration`` (mapping ``float64`` to ``double``/``type(0d0)``
    in C/Fortran respectively).

- Week 2:

  - Implement precision controlled printing in ``C99CodePrinter``, e.g.:
    ``sinf``/``sin``/``sinl`` for all math functions in ``math.h``.
  - Use literals consistent with choice of precision (``0.7F``,
    ``0.7``, ``0.7L``) (resolves gh-11803_)
  - Implement per printer instance header and library tracking.

- Week 3:

  - Add a setting to the ``CCodePrinter`` whether to use math macros (they
    are not required by the standard), and when in use, use them more
    extensively.
  - Add a ``C11CodePrinter`` with complex number construction macros.
  - Add C99 & C11 `complex math functions
    <http://en.cppreference.com/w/c/numeric/complex>`_ to the C-code
    printers. 
  - Implement precision controlled printing in ``FCodePrinter``, e.g.:
    ``cmplx(re, im, kind)``.

- Week 4:

  - Add support for ``boost::multiprecision`` in a new
    ``CXX11CodePrinter`` subclass.
  - Add new types to ``sympy.codegen.ast`` related to program flow,
    *e.g.* ``While``, ``FunctionDefinition``, ``FunctionPrototype``
    (for ``C``), ``ReturnStatement``, ``PrinterSetting``, *etc.*

- Week 5:

  - Introduce a new module ``sympy.codegen.algorithms`` containing *e.g.*
    Newton's method, fixed point iteration, *etc.*
  - Since Phase I will largely be about adding new AST node types
    they could be merged as a PR by the end of Phase I (or
    incrementally during the Phase I). Perhaps marked as provisional
    to allow changes without deprecatation cycle if needed later
    during the program.
  - Hand-in evaluation of Phase I.


Phase II, 2017-07-01 – 2017-07-28
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The second phase will focus on putting the new higher-level constructs
for code-generation into use using algorithms. In many ways this will
pave the way for more capable ``CodeGen`` classes.

- Week 6-8:

  - Handle special function definition attributes in C/C++/Fortran
    *e.g.* static/constexpr/bind(c)
  - Write a Python code printer class using the new.
    (addresses gh-12213_)
  - A new ``CodeGen``-like class using the new AST types & updated
    printers.
  - Attend the SciPy 2017 conference and get user feedback on
    code-generation.

- Week 9:

  - Phase II, will mostly focus on providing facilities for a
    future replacement/enhanced version of the ``CodeGen`` class, during
    this work, it is likely that the printers and ``codegen.ast``
    modules have been updated.
  - Hand-in evaluation of Phase II.

Phase III,  2017-07-29 – 2017-08-29
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The third phase will focus on providing expression rewriting
facilities for significance preservation and optimizations. The
optimization framework will use the pattern matching capabilities.

Note that is not only something that
SymPy's code printers could benefit from, but also ``Lambdify`` (using
the ``LLVMDoubleVisistor``) in SymEngine.

Different domains need different functions of this kind, the focus should
therefore be to provide tooling for users to create their own
functions. An often used technique is tabulation, polynomial
interpolation and newton refinement. Based on the work in Phase I &
II, SymPy will be very well equipped to aid in this process (table
generation for different precisions, code for iterative refinement).

- Week 10 - 12:

  - Implement the equivalent functionality of the `optimizations.py
    <https://github.com/bjodah/gsoc2017-bjodah/blob/master/application/optimizations.py>`_
    and `approximations.py <https://github.com/bjodah/gsoc2017-bjodah/blob/master/application/approximations.py>`_
    from the examples above.
  - Utilities for tabulation.

- Week 13

  - Final evaluation, fixes to documentation, addressing reviews.


After GSoC
~~~~~~~~~~
I will resume my post-graduate studies and hopefully leverage the new
code-generation facilities in future applied research projects.

.. _gh-11038: https://github.com/sympy/sympy/issues/11038
.. _gh-11803: https://github.com/sympy/sympy/issues/11803
.. _gh-12213: https://github.com/sympy/sympy/issues/12213
