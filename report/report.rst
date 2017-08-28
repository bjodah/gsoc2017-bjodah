GSoC 2017 Report Björn Dahlgren: Improved code-generation facilities
====================================================================


About Me
--------
My name is Björn Dahlgren, and I am a PhD student at KTH Royal
Institute of Technology, Stockholm, Sweden.

Introduction
------------
My project was to enhance the code-generation facilities of SymPy.
You can read my `proposal
<https://github.com/sympy/sympy/wiki/GSoC-2017-Application-Bj%C3%B6RN's-Dahlgren:-Improved-code-generation-facilities>`_
for the motivation behind this work. The overall goals were the
following:

- Allow to render code targeting a specific precision (e.g. binary32
  vs. binary64 floating point numbers). Prior to this project the
  printers would sometimes generate code containing a mixture of single,
  double and extended precision, and there were no way to change this
  short of subclassing the printers and overriding the methods.
- Allow to render blocks of code and not only expressions. There was
  an initial effort to support this in the submodule
  ``sympy.codegen``.
- Improve the ``Lambdify`` functionality in SymEngine's python
  wrapper. Before this project it did not handle outputs of mixed
  shape, and it also had considerable overhead.

Summary of the final work product
---------------------------------
A whole new repository with code and notebooks for code-generation was
created during the first part of GSoC:

- https://github.com/sympy/scipy-2017-codegen-tutorial

Jason Moore, Kenneth Lyons, Aaron Meurer and I (my `commits <https://github.com/sympy/scipy-2017-codegen-tutorial/commits/master?author=bjodah>`_) created this for the
tutorial in code generation with SymPy at the SciPy 2017 conference.

The majority of the work are contained in these pull-requests:

- symengine.py, `#112 <https://github.com/symengine/symengine.py/pull/112>`_ (merged):
  Heterogeneous output in Lambdify.
- symengine.py, `#171
  <https://github.com/symengine/symengine.py/pull/171>`_ (merged):
  Bug fix for heterogeneous output in Lambdify.
- sympy, `#12693 <https://github.com/sympy/sympy/pull/12693>`_
  (merged): Extending the ``sympy.codegen.ast`` module with new
  classes (for generating ASTs).
- sympy, `#12808 <https://github.com/sympy/sympy/pull/12808>`_
  & `#13046 <https://github.com/sympy/sympy/pull/13046>`_ (merged):
  PythonCodePrinter, MpmathPrinter, SymPyPrinter NumPyPrinter, SciPyPrinter.
- sympy, `#13194 <https://github.com/sympy/sympy/pull/13063>`_ (open):
  Add ``.codegen.rewriting`` module.
- sympy, `#13200 <https://github.com/sympy/sympy/pull/13200>`_ (merged):
  Add ``.codegen.approximations`` module.
- sympy, `#13100 <https://github.com/sympy/sympy/pull/13100>`_ (open):
  More AST nodes. Building on #12693, this is the biggest PR. In
  addition to improving the AST nodes it introduces
  ``.codegen.algorithms`` as well as an internal testing module
  ``.utilities._compilation`` which allows to compile and import/run 
  strings of C/C++/Fortran code.
  

In addition there were smaller pull-requests made & merged:

- sympy_benchmarks: `#37  <https://github.com/sympy/sympy_benchmarks/pull/37>`_,
  `#38 <https://github.com/sympy/sympy_benchmarks/pull/38>`_,
  `#39 <https://github.com/sympy/sympy_benchmarks/pull/39>`_,
  `#40 <https://github.com/sympy/sympy_benchmarks/pull/40>`_:
  Benchmarks for lambidfy and common sub-expression elimination.
- sympy: `#12686 <https://github.com/sympy/sympy/pull/12686>`_
  (Support for __abs__ in SymPy matrices),
  `#12692 <https://github.com/sympy/sympy/pull/12692>`_ (subclass support for
  SymPy's deprecation decorator), `#12762
  <https://github.com/sympy/sympy/pull/12762>`_ (Fix floating point
  error under windows),
  `#12805 <https://github.com/sympy/sympy/pull/12805>`_ Revert change to
  cse (performance regression), `#12764
  <https://github.com/sympy/sympy/pull/12764>`_ environment variable use,
  `#12833 <https://github.com/sympy/sympy/pull/12883>`_ string formatting,
  `#12944 <https://github.com/sympy/sympy/pull/12944>`_ allow relative
  path in autowrap,
  `#13063 <https://github.com/sympy/sympy/pull/13063>`_ fix test timing script
  (and updated timings),
  `#12833 (some of the commits) <https://github.com/sympy/sympy/pull/12833>`_ Allow custom class
  in autowrap & codegen,
  `#12843 (one of the commits) <https://github.com/sympy/sympy/pull/12843>`_ allow changing compile
  arguments in ``CythonCodeWrapper``.
  

Detailed review of the work
---------------------------
The first weeks of the summer was mostly spent on the code generation
material presented at the SciPy conference tutorial, in parallel with
that work was done to handle different choices of data types in the
printers. And new AST nodes were introduced to represent type.

Code for the tutorial
~~~~~~~~~~~~~~~~~~~~~
During the writing of this code improvements were made to the existing
code-generation facilities and SymPy (and experience with their
shortcomings were gained). One of the challenges in this work was that
the attendees at the conference would be using all major platforms
(Linux/macOS/Windows) and different Python versions, we needed to
ensure that generating code, compiling, linking and importing worked
all combinations.

Lambdify in SymEngine's python wrapper
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Writing the code for the tutorial provided great test cases for the
code-generation capabilities of SymPy. The motivation of doing code
generation is usually that of speed (but sometimes it may be motivated
by wanting to work with some library written in another language). An
alternative to generating high level code which then gets compiled, is
to go toward assembly (or some intermediate representation). SymEnigne
had support for doing this via LLVM's JIT compiler. The Python
bindings however needed an overhaul (something I had included in the
time-line in my proposal), and now I wanted to use ``Lambdify`` (the
SymEngine version of ``sympy.lambdify``), and together with the help
of Isuru Fernando we got it to work (and benchmarks for `pydy
<https://pydy.org>`_ show that it is even faster than using the cython
backend).
  
AST nodes
~~~~~~~~~
I had made AST nodes in my prototype for my proposal, right at the
start of the project I ported those to SymPy. It took some rewriting
and discussion with Aaron (both during our weekly meetings and at the
conference) to get it to a point where we were confident enough to
merge it into SymPy's codebase.

One of the major challanges when designing the new classes for
``sympy.codegen.ast`` was dealing with optional arguments in our
subclasses of ``symyp.core.basic.Basic``. The solutions which worked
best was to have a subclass ``sympy.codegen.Node`` which stored such
optinoal information as instances in a SymPy ``Tuple`` as its last
argument (accessible as ``.attrs`). This allowed the code
printers for Python, C and Fortran to support the same ``Variable`` class
for instance, where the C printer would also look for attributes
"value_const", "volatile" etc. and the Fortran printer would look for
e.g. "intent".

Language specific nodes have been added under their own submodules in
``sympy.codegen`` (e.g. ``sympy.codegen.fnodes`` for Fortran and
``sympy.codegen.cnodes`` for C). The most common statements are now
implmeneted, but the nodes are by far not exhaustive. There are now
also helper functions for generating e.g. modules in
``sympy.codegen.pyutils`` & ``sympy.codegen.futils`` (for Python and
Fortran respectively).

Code printers
~~~~~~~~~~~~~
Dealing with floating point types is
tricky since one want to be pragmatic in order for the types to be
helpful (IEEE 754 conformance is assumed), but general enough that
people targeting hardware with non-standard conformance can still
generate useful code using SymPy. For example, one can now choose
the targeted precision::

  >>> from sympy import ccode, symbols, Rational
  >>> x, tau = symbols("x, tau")
  >>> expr = (2*tau)**Rational(7, 2)
  >>> from sympy.codegen.ast import real, float80
  >>> ccode(expr, type_aliases={real: float80})
  '8*M_SQRT2l*powl(tau, 7.0L/2.0L)'

Here we have assumed that the targeted architechture has x87 FPU (long
double is a 10 byte extended precision floating point data type). But
it is fully possible to generate code for some other targeted
precision, e.g. GCC's software implemented float128::

  >>> from sympy.printing.ccode import C99CodePrinter
  >>> from sympy.codegen.ast import FloatType
  >>> f128 = FloatType('_Float128', 128, nmant=112, nexp=15)
  >>> p128 = C99CodePrinter(dict(
  ...     type_aliases={real: f128},
  ...     type_literal_suffixes={f128: 'Q'},
  ...     type_func_suffixes={f128: 'f128'},
  ...     type_math_macro_suffixes={
  ...         real: 'f128',
  ...         f128: 'f128'
  ...     },
  ...     type_macros={
  ...         f128: ('__STDC_WANT_IEC_60559_TYPES_EXT__',)
  ...     },
  ...     math_macros={}
  ... ))
  >>> p128.doprint(tau**Rational(7, 2))
  'powf128(tau, 7.0Q/2.0Q)'

For generating Python code there was previosuly one function
(``sympy.printing.python``) which generated code dependent on SymPy.
During the project a proper code printer for Python was introduced
(an example of its output is shown later). The much used function
``lambdify`` was also changed to use this new printer. Introducing
such a big change without breaking backward compatibility was
certainly a challenge, but the benefit is that the user may now
subclass the printers to override their default behaviour and use
their custom printer in ``lambdify``.

Rewriting
~~~~~~~~~
One usual challenge when working with symbolic expressions is that
there are many ways to write the same expresisons. For code-generation
purposes we want to write it in a manner which maximizes performance
and minimizes significance loss (or let the user make that choice when
the two are at odds). Since SymPy already has a great tools for
traversing the expression tree and applying quite advanced pattern
matching based replacements using ``Wild`` it was reasonably
straightforward to implement rewriting rules for transforming e.g.
``2**x`` to ``exp2(x)`` etc. Using the same structure, rules for
rewriting expressions to drop small elements in sums (based on a
user-predefined bounds).

Algorithms
~~~~~~~~~~
One of the great benefitst from being able to represent abstract
syntax trees as (largetly) language agnostic SymPy obejcts is that we
can create functions for building these trees. Simpler numerical
algorithms (which are ubiquitous in scientific codes) can be collected
under ``sympy.codegen.algorithms``. As a first case Newton's
algortihm was implemented::

  >>> from sympy import cos
  >>> from sympy.codegen.algorithms import newtons_method_function
  >>> ast = newtons_method_function(cos(x) - x**3, x)
  >>> print(ccode(ast))
  double newton(double x){
     double d_x = INFINITY;
     while (fabs(d_x) > 9.9999999999999998e-13) {
        d_x = (pow(x, 3) - cos(x))/(-3*pow(x, 2) - sin(x));
        x += d_x;
     }
     return x;
  }

once we have the AST we can print it using the python code printer as well::

  >>> from sympy.printing import pycode
  >>> print(pycode(ast))
  def newton(x):
      d_x = float('inf')
      while abs(d_x) > 1.0e-12:
          d_x = (x**3 - math.cos(x))/(-3*x**2 - math.sin(x))
          x += d_x
      return x

or the Fortran code printer::

  >>> from sympy.printing import fcode
  >>> print(fcode(ast, source_format='free', standard=2003))
  real*8 function newton(x)
  real*8 :: x
  real*8 :: d_x = (huge(0d0) + 1)
  do while (abs(d_x) > 1.0d-12)
     d_x = (x**3 - cos(x))/(-3*x**2 - sin(x))
     x = x + d_x
  end do
  newton = x
  end function

Newton's method is quite simple, but what makes SymPy suitable for
this is that it needs the ratio between the function and its
derivative.

Conclusion
----------
I think that I managed to address all parts of my proposal. That being
said, there is still a lot of potential to expand the
``sympy.codegen`` module. But now there are purposefully made base
classes for creating AST node classes (``sympy.codegen.ast.Token`` &
``sympy.codegen.ast.Node``), the language agnostic ones are general enough
that an algorithm represented as a single AST can be printed as
Python/C/Fortran. At some level code will still be needed to be
written manually (presumably as templates), but the amount of template
rendering logic can be significantly reduced. Having algorithm AST
factories such as the one for Newton's method in
``sympy.codegen.ast.algorithms`` is also exciting since those
algorithms can be unit-tested as part of SymPy. Ideas for furthor work
on code-generation with SymPy have been added to `the list
<https://github.com/sympy/sympy/wiki/GSoC-2018-Ideas#code-generation>`_
of potential ideas for next years GSoC.

Post-GSoC
---------
I plan to continue to contribute to the SymPy project, and start using
the new resources in my own research. Working with the new classes
should also allow us to refine them if needed (preferably before the
next release is tagged in order to avoid having to introduce
deprecation cycles). SymPy is an amazing project with
a great community. I'm really grateful to Google for funding me (and
others) to do a full summers work on this project.
