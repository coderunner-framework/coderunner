CodeRunner
==========

CodeRunner is a framework for the automated running and analysis of
simulations. It automatically generates any necessary input files, organises
the output data and analyses it. Because it is a modular system, it can easily
be customised to work with any system and any simulation code.

Installation
============

CodeRunner requires several system dependencies which are explained in the
`dependencies/README.md` file. Short guide:

1. `cd dependencies`
2. `./download_dependencies`
3. `make hd all rb PREFIX=/path/to/install/dir`
4. Add the following to your `.bashrc`: `export PATH=/path/to/install/dir:$PATH`
5. Finally install using: `gem install coderunner`

Coding Style Guide
==================

These bullet points are taken from here: https://github.com/bbatsov/ruby-style-guide

* Indentation is strictly two spaces, i.e. not tabs.
* Where possible do not exceed 80 columns. This makes the code much more
  readable.
* Avoid unnecessary comments or inline comments, try to write code which is
  self documenting or have a short comment preceding your code.
* Do not use the ';' character to write several statements on one line.
* If in doubt refer to the style guide.

Copyright
=========

Copyright (c) 2016 Edmund Highcock. See LICENSE.txt for further details.

