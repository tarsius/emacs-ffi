TOP := $(dir $(lastword $(MAKEFILE_LIST)))

EMACS       ?= emacs
EMACS_ARGS  ?=
EMACS_Q_ARG ?= -Q
EMACS_BATCH ?= $(EMACS) $(EMACS_Q_ARG) --batch $(EMACS_ARGS) $(LOAD_PATH)

LDFLAGS ?= -shared
LIBS    ?= -lffi -lltdl
CFLAGS  ?= -g3 -Og -finline-small-functions -shared -fPIC

# Set this to debug "make test":
# GDB = gdb --args
