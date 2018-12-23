# DependencyTrees.jl

[![Build Status](https://travis-ci.org/dellison/DependencyTrees.jl.svg?branch=master)](https://travis-ci.org/dellison/DependencyTrees.jl) [![CodeCov](https://codecov.io/gh/dellison/DependencyTrees.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dellison/DependencyTrees.jl)

DependencyTrees.jl is a Julia package for dependency parsing of natural language.

Implements the following transition systems:

* Arc-Standard (with static oracle)
* Arc-Eager (with static and dynamic oracles)
* Arc-Hybrid (with static and dynamic oracles)
* Arc-Swift (with static oracle)
* Nivre 08's List-Based Non-Projective (with static oracle)
