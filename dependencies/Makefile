# Makefile for installing CodeRunner dependencies
# Written by Edmund Highcock Oct 2012
# edmundhighcock@sourceforge.net
#

MY_MAKEFLAGS?=
MY_CONFFLAGS=LDFLAGS=-L${PREFIX}/lib CFLAGS=-I${PREFIX}/include

# Packages
NETCDF="netcdf-4.4.0"
GSL="gsl-2.1"
HDF5="hdf5-1.8.16"
YAML="yaml-0.1.6"
READLINE="readline-6.3"
NCURSES="ncurses-6.0"
RUBY_VERSION="2.3.1"

help:
	@echo
	@echo "----------------------------------------------------------------"
	@echo " Please see the README.md"
	@echo "----------------------------------------------------------------"

.default_goal: help

all: hdf5 netcdf gsl readline yaml ncurses rvm

gsl:
	tar -xzf ${GSL}.tar.gz
	cd ${GSL}; ./configure --prefix=${PREFIX} && make ${MY_MAKEFLAGS} && make install ${MY_MAKEFLAGS}

hdf5:
	tar -xzf ${HDF5}.tar.gz
	cd ${HDF5}; ./configure --prefix=${PREFIX} && make ${MY_MAKEFLAGS} && make install ${MY_MAKEFLAGS}

netcdf:
	tar -xzf ${NETCDF}.tar.gz
	cd ${NETCDF}; ./configure ${MY_CONFFLAGS} --prefix=${PREFIX} --enable-shared --enable-netcdf4 && make ${MY_MAKEFLAGS} && make install ${MY_MAKEFLAGS}

yaml:
	tar -xzf ${YAML}.tar.gz
	cd ${YAML}; ./configure --prefix=${PREFIX} && make ${MY_MAKEFLAGS} && make install ${MY_MAKEFLAGS}

readline:
	tar -xzf ${READLINE}.tar.gz
	cd ${READLINE}; ./configure --prefix=${PREFIX} &&  make ${MY_MAKEFLAGS}  && make install ${MY_MAKEFLAGS}

ncurses:
	tar -xzf ${NCURSES}.tar.gz
	cd ${NCURSES};  ./configure --prefix=${PREFIX} --with-shared &&  make ${MY_MAKEFLAGS}  && make install ${MY_MAKEFLAGS}

rvm:
	\curl -sSL https://get.rvm.io | bash -s stable --auto-dotfiles
	@echo "----------------------------------------------------------------"
	@echo "To complete RVM/Ruby installation run the following commands:"
	@echo ""
	@echo "source $$HOME/.rvm/scripts/rvm"
	@echo "rvm autolibs disable"
	@echo "rvm install ruby-${RUBY_VERSION} -j 4"
	@echo "----------------------------------------------------------------"

clean:
	rm -rf ${NETCDF} ${YAML} ${READLINE} ${GSL}
	rm -rf ${NCURSES} ${HDF5}
