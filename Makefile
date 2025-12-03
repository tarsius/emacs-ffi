-include config.mk
include default.mk

PKG = ffi

ELS   = ffi.el
ELS  += test.el
ELCS  = $(ELS:.el=.elc)

DEPS  =

LOAD_PATH ?= -L .

all: modules lisp

help:
	$(info make all        -- Build modules and lisp)
	$(info make modules    -- Build modules)
	$(info make lisp       -- Build lisp)
	$(info make redo       -- Re-build from scratch)
	$(info make test       -- Run tests)
	$(info make clean      -- Remove built files)
	@printf "\n"

redo: clean all

modules: ffi-module.so test.so

ffi-module.so: ffi-module.o
	$(CC) $(LDFLAGS) -o ffi-module.so ffi-module.o $(LIBS)

test.so: test.o
	$(CC) $(LDFLAGS) -o test.so test.o

lisp: $(ELCS) autoloads check-declare

autoloads: $(PKG)-autoloads.el

%.elc: %.el
	@printf "Compiling $<\n"
	@$(EMACS_BATCH) --funcall batch-byte-compile $<

check-declare:
	@printf " Checking function declarations\n"
	@$(EMACS_BATCH) --eval "(check-declare-directory default-directory)"

test: modules lisp
	@printf "  Testing...\n"
	@export LD_LIBRARY_PATH="$(TOP):$$LD_LIBRARY_PATH"; \
	$(GDB) $(EMACS_BATCH) --load test.el \
	--funcall ert-run-tests-batch-and-exit

CLEAN = $(ELCS) $(PKG)-autoloads.el *.o *.so *.dylib

clean:
	@printf " Cleaning...\n"
	@rm -rf $(CLEAN)

$(PKG)-autoloads.el: $(ELS)
	@printf " Creating $@\n"
	@$(EMACS) -Q --batch --eval "\
(let ((inhibit-message t))\
  (loaddefs-generate\
   default-directory \"$@\" nil\
   (prin1-to-string\
    '(add-to-list 'load-path\
                  (or (and #$$ (directory-file-name (file-name-directory #$$)))\
                      (car load-path)))))\
   nil t)"
