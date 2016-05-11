System dependencies
===================

CodeRunner requires the following system-level dependencies:

1. GSL
2. HDF5
3. ncurses
4. NetCDF
5. readline
6. Ruby
7. yaml

To install these, there are two option:

1. Install through a package manager (recommended).
2. Install using the from source.

In some cases, packages downloaded through the system package manager are too
old for some RubyGems. In that case follow the manual installation below.

Manual Installation
=================

Some supercomputing environments require some configuration before being
able to compile software. See if there is a configuration file in the
`system_config_files` directory and `source` it. If not, things should work
or they won't, in which case open an issue on GitHub.

1. Before installing, export install PATH by adding the following to your
   `.bashrc`:
   `export PATH=/path/to/install/dir:$PATH`
   Why? When RVM compiles Ruby it will look in the path for yaml and readline
   in order to compile Ruby with these enabled.
2. Run `./download_dependencies.sh -P /path/to/download/dir`. Default
   location is in the dependencies directory.
3. If you are unsure what your system has, compile all the packages by
   running `make all PREFIX=/path/to/install/dir`.
4. RVM installation requires manual steps printed out at the end of the compile
   process - run these.
5. If you only want to build one package, substitute `all` for the name of
   the package. If you find any of these out of date, please open an
   issue on GitHub. Considerations when installing single packages:
  1. `hdf5` must be installed before `netcdf`.
  2. `yaml` and `readline` must be installed before Ruby.

