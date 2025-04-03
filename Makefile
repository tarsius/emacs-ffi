# SPDX-License-Identifier: GPL-3.0-or-later

TOP := $(dir $(lastword $(MAKEFILE_LIST)))

-include config.mk
include default.mk

PKG = ffi

ELS   = ffi.el
ELS  += test.el
ELCS  = $(ELS:.el=.elc)

EMACS      ?= emacs
EMACS_ARGS ?=
LOAD_PATH  ?= -L .

LDFLAGS ?= -shared
LIBS    ?= -lffi -lltdl
CFLAGS  ?= -g3 -Og -finline-small-functions -shared -fPIC

# Set this to debug "make test":
# GDB = gdb --args

all: module test-module lisp

help:
	$(info make all          - generate lisp and manual)
	$(info make test         - run tests)
	$(info make clean        - remove generated files)
	@printf "\n"

module: ffi-module.so

ffi-module.so: ffi-module.o
	$(CC) $(LDFLAGS) -o ffi-module.so ffi-module.o $(LIBS)

ffi-module.o: ffi-module.c

test-module: test.so

test.so: test.o
	$(CC) $(LDFLAGS) -o test.so test.o

test.o: test.c

lisp: $(ELCS) loaddefs check-declare

loaddefs: $(PKG)-autoloads.el

%.elc: %.el
	@printf "Compiling $<\n"
	@$(EMACS) -Q --batch $(EMACS_ARGS) $(LOAD_PATH) -f batch-byte-compile $<

check-declare:
	@printf " Checking function declarations\n"
	@$(EMACS) -Q --batch $(EMACS_ARGS) $(LOAD_PATH) \
	--eval "(check-declare-directory default-directory)"

$(PKG)-autoloads.el: $(ELS)
	@printf " Creating $@\n"
	@$(EMACS) -Q --batch -l autoload -l cl-lib --eval "\
(let ((file (expand-file-name \"$@\"))\
      (autoload-timestamps nil) \
      (backup-inhibited t)\
      (version-control 'never)\
      (coding-system-for-write 'utf-8-emacs-unix))\
  (write-region (autoload-rubric file \"package\" nil) nil file nil 'silent)\
  (cl-letf (((symbol-function 'progress-reporter-do-update) (lambda (&rest _)))\
            ((symbol-function 'progress-reporter-done) (lambda (_))))\
    (let ((generated-autoload-file file))\
      (update-directory-autoloads default-directory))))" \
	2>&1 | sed "/^Package autoload is deprecated$$/d"

test: ffi-module.so test.so
	export LD_LIBRARY_PATH="$(TOP):$$LD_LIBRARY_PATH"; \
	$(GDB) $(EMACS) -Q --batch $(EMACS_ARGS) $(LOAD_PATH) -l test.el \
	-f ert-run-tests-batch-and-exit

clean:
	@printf " Cleaning *...\n"
	@rm -rf $(ELCS) $(PKG)-autoloads.el *.o *.so *.dylib
