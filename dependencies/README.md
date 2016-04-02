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

The exact versions required can be read from the `download_dependencies.sh`
script and the user has two options:

1. Install the packages using the from source (recommended).
2. Install the packages through a package manager.

The packages downloaded by the `download_dependencies.sh` and built using the
Makefile are guaranteed to work and avoids having to deal with the headaches of
package compatibility.

Installing using the shell script and Makefile
==============================================

1. Run `./download_dependencies.sh -P /path/to/download/dir`. Default
   location is in the dependencies directory.
2. To compile all the packages, run `make hd all rb PREFIX=/path/to/install/dir`.
3. Finally, export these to the system PATH by adding the following to your
   `.bashrc`:

   `export PATH=/path/to/install/dir:$PATH`
