# This Makefile is only intended to prepare for distribution the PyTables
# sources exported from a repository.  For building and installing PyTables,
# please use ``setup.py`` as described in the ``README.rst`` file.

VERSION = $(shell cat VERSION)
SRCDIRS = src doc
GENERATED = ANNOUNCE.txt
PYTHON = python3
PYPLATFORM = $(shell $(PYTHON) -c "from distutils.util import get_platform; print(get_platform())")
PYVER = $(shell $(PYTHON) -V 2>&1 | cut -c 8-10)
PYBUILDDIR = $(PWD)/build/lib.$(PYPLATFORM)-$(PYVER)
OPT = PYTHONPATH=$(PYBUILDDIR)


.PHONY: all dist build check heavycheck clean distclean html

all: $(GENERATED) build html

dist: all latex
	$(PYTHON) setup.py sdist
	cp RELEASE_NOTES.txt dist/RELEASE_NOTES-$(VERSION).txt
	cp doc/usersguide-$(VERSION).pdf dist/pytablesmanual-$(VERSION).pdf
	tar cvzf dist/pytablesmanual-$(VERSION)-html.tar.gz doc/html
	cd dist && \
	md5sum -b tables-$(VERSION).tar.gz RELEASE_NOTES-$(VERSION).txt \
	pytablesmanual-$(VERSION).pdf \
	pytablesmanual-$(VERSION)-html.tar.gz > pytables-$(VERSION).md5 && \
	cd -

clean:
	$(RM) -r MANIFEST build dist tmp tables/__pycache__
	$(RM) bench/*.h5 bench/*.prof
	$(RM) -r examples/*.h5 examples/raw
	$(RM) -r *.egg-info
	$(RM) $(GENERATED) tables/*.so a.out
	find . '(' -name '*.py[co]' -o -name '*~' ')' -exec rm '{}' ';'
	for srcdir in $(SRCDIRS) ; do $(MAKE) -C $$srcdir $(OPT) $@ ; done

distclean:	clean
	$(MAKE) -C src $(OPT) $@
	$(RM) tables/_comp_*.c tables/*extension.c
	$(RM) doc/usersguide-*.pdf
	$(RM) -r doc/html
	#git clean -fdx

html: build
	$(MAKE) -C doc $(OPT) html
	$(RM) -r doc/html
	cp -R doc/build/html doc/html

latex:
	$(MAKE) -C doc $(OPT) latexpdf
	$(RM) doc/usersguide-*.pdf
	cp doc/build/latex/usersguide-$(VERSION).pdf doc

%: %.in VERSION
	cat "$<" | sed -e 's/@VERSION@/$(VERSION)/g' > "$@"

build:
	$(PYTHON) setup.py build

check: build
	cd build/lib.*-$(PYVER) && env PYTHONPATH=. $(PYTHON) tables/tests/test_all.py

heavycheck: build
	cd build/lib.*-$(PYVER) && env PYTHONPATH=. $(PYTHON) tables/tests/test_all.py --heavy
