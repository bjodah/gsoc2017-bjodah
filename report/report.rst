GSoC 2017 Report Björn Dahlgren: Improved code-generation facilities

About Me
--------
My name is Björn Dahlgren, and I am a PhD student at KTH Royal
Institute of Technology, Stockholm, Sweden.

Introduction
------------
My project was to enhance the code-generation facilities of SymPy.
You can read my `proposal
<https://github.com/sympy/sympy/wiki/GSoC-2017-Application-Bj%C3%B6rn-Dahlgren:-Improved-code-generation-facilities>`_
for the motivation behind this work. The overall goals were the
following:

- Allow to render code targeting a specific precision (e.g. binary32
  vs. binary64 floating point numbers). Prior to this project the
  printers would sometimes generate code containing a mixture of single,
  double and extended precision, and there were no way to change this
  short of subclassing the printers and overriding the methods.
- Allow to render blocks of code and not only expressions. There was
  an initial effort to support this in the submoduel
  ``sympy.codegen``.
- Improve the ``Lambdify`` functionality in SymEngine's python
  wrapper. Before this project it did not handle outputs of mixed
  shape, and it also had consideralbe overhead.

Summary of the final work product
---------------------------------
A whole new repository with code and notebooks for code-generation was
created during the first part of GSoC:

- https://github.com/sympy/scipy-2017-codegen-tutorial

Jason Moore, Kenneth Lyons, Aaron Meurer and I (my `commits <https://github.com/sympy/scipy-2017-codegen-tutorial/commits/master?author=bjodah>`) created this for the
tutorial in codegeneration with SymPy at the SciPy 2017 conference.

The majority of the work are contained in these pull-reqeusts:
- symengine.py, `#112
  <https://github.com/symengine/symengine.py/pull/112>`_ (merged):
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
- sympy, `#13200 <https://github.com/sympy/sympy/pull/13200>`_ (open):
  Add ``.codegen.approximations`` module.
- sympy, `#13100 <https://github.com/sympy/sympy/pull/13100>`_ (open):
  More AST nodes. Building on #12693, this is the biggest PR. In
  addition to improving the AST nodes it introduces
  ``.codegen.algorithms`` as well as an internal testing module
  ``.utilities._compilation`` which allows to compile and import/run 
  strings of C/C++/Fortran code.
  

In addition there were smaller pull-requests made & merged:
- sympy_benchmarks: `#37
  <https://github.com/sympy/sympy_benchmarks/pull/37>`_, `#38
  <https://github.com/sympy/sympy_benchmarks/pull/38>`_, `#39
  <https://github.com/sympy/sympy_benchmarks/pull/39>`_, `#40
  <https://github.com/sympy/sympy_benchmarks/pull/40>`_:
  Benchmarks for lambidfy and common subexpression elimination.
- sympy: `#12686 <https://github.com/sympy/sympy/pull/12686>`_
  (Support for __abs__ in SymPy matrices), `#12692
  <https://github.com/sympy/sympy/pull/12692>`_ (subclass support for
  SymPy's deprecation decorator), `#12762
  <https://github.com/sympy/sympy/pull/12762>`_ (Fix floating point
  error under windows), `#12805
  <https://github.com/sympy/sympy/pull/12805>`_ Revert change to
  cse (performance regression), `#12764
  <https://github.com/sympy/sympy/pull/12764>`_ environemnt variable use, `#12833
  <https://github.com/sympy/sympy/pull/12883>`_ string formatting,
  `#12944 <https://github.com/sympy/sympy/pull/12944>`_ allow relative
  path in autowrap, `#13063
  <https://github.com/sympy/sympy/pull/13063>`_ fix test timing script
  (and updated timings), `#12833 (some of the commits)
  <https://github.com/sympy/sympy/pull/12833>`_ Allow custom class
  in autowrap & codegen, `#12843 (one of the commits)
  <https://github.com/sympy/sympy/pull/12843>`_ allow changing compile
  args in ``CythonCodeWrapper``.
  

Detailed review of the work
---------------------------
The first weeks of the summer was mostly spent on the code generation
material presented at the SciPy conference tutorial.

I think that I managed to address all parts of my proposal. That being
said, there is still a lot of potential to expand the
``sympy.codegen`` module. But now there are purposfully made base
classes for creating AST node classes (``sympy.codegen.ast.Token`` &
``sympy.codegen.ast.Node``).

Lambdify in SymEngine's python wrapper
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Prior to the GSoC project I had started work on supporting
heterogenous output from ``Lambdify`` in ``symengine.py`` (in `this
pull-request <https://github.com/symengine/symengine.py/pull/112>`_).
As part of my plan for 
  
AST nodes
~~~~~~~~~

Code printers
~~~~~~~~~~~~~


Post-GSoC
---------
I plan to continue to contribute to the SymPy project, and start using
the new...
