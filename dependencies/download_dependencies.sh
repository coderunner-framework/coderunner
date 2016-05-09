#!/bin/bash

DIR="$PWD"

while [ $# -gt 0 ]
do
    case "$1" in
        -P) DIR="$2"; shift
    esac
    shift
done

wget -nc ftp://ftp.gnu.org/gnu/gsl/gsl-2.1.tar.gz -P $DIR
wget -nc https://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8.16/src/hdf5-1.8.16.tar.gz -P $DIR
wget -nc ftp://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz -P $DIR
wget -nc ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.4.0.tar.gz -P $DIR
wget -nc ftp://ftp.gnu.org/gnu/readline/readline-6.3.tar.gz -P $DIR
wget -nc http://pyyaml.org/download/libyaml/yaml-0.1.4.tar.gz -P $DIR
wget -nc https://cache.ruby-lang.org/pub/ruby/ruby-2.3.0.tar.gz -P $DIR

