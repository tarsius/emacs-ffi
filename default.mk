# SPDX-License-Identifier: GPL-3.0-or-later

TOP := $(dir $(lastword $(MAKEFILE_LIST)))

EMACS      ?= emacs
EMACS_ARGS ?=
LOAD_PATH   = -L $(TOP) -L $(TOP)/test

LDFLAGS ?= -shared
LIBS    ?= -lffi -lltdl
CFLAGS  ?= -g3 -Og -finline-small-functions -shared -fPIC

# Set this to debug "make test":
# GDB = gdb --args
