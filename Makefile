# SPDX-License-Identifier: GPL-3.0-or-later

-include config.mk
include default.mk

EMACS      ?= emacs
EMACS_ARGS ?=
LOAD_PATH  ?= -L .

LDFLAGS ?= -shared
LIBS    ?= -lffi -lltdl
CFLAGS  ?= -g3 -Og -finline-small-functions -shared -fPIC

# Set this to debug "make check":
# GDB = gdb --args

all: module test-module

module: ffi-module.so

ffi-module.so: ffi-module.o
	$(CC) $(LDFLAGS) -o ffi-module.so ffi-module.o $(LIBS)

ffi-module.o: ffi-module.c

check: ffi-module.so test.so
	LD_LIBRARY_PATH=`pwd`:$$LD_LIBRARY_PATH; \
	  export LD_LIBRARY_PATH; \
	$(GDB) $(EMACS) -Q --batch $(EMACS_ARGS) $(LOAD_PATH) -l test.el \
	-f ert-run-tests-batch-and-exit

test-module: test.so

test.so: test.o
	$(CC) $(LDFLAGS) -o test.so test.o

test.o: test.c

clean:
	-rm -f ffi.elc ffi-autoloads.el ffi-module.o ffi-module.so
	-rm -f test.o test.so
