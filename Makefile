# cl-release

.POSIX:
.SUFFIXES:
.SUFFIXES: sh

VERSION=1.5.0
CL_RELEASE=cl-release-$(VERSION)
DOTEMACS=$(HOME)/.emacs.d/init.el

# paths
scrdir=.
prefix=/usr/local
exec_prefix=$(prefix)
bindir=$(exec_prefix)/bin

# tools
INSTALL=/usr/bin/install

# files
SRCS=$(wildcard *.sh)
OBJS=$(SRCS:.sh=)

all: $(OBJS)

%: %.sh
	cp $< $@

clean:
	-rm $(OBJS)

distclean: clean
	-rm -rf dist
	-rm $(CL_RELEASE).tar.gz

dist: distclean
	mkdir -p dist/$(CL_RELEASE)
	cp -R $(SRCS) Makefile doc README.txt dist/$(CL_RELEASE)
	cd dist && tar czf ../$(CL_RELEASE).tar.gz $(CL_RELEASE)
	rm -rf dist

install: all installdirs
	$(INSTALL) $(OBJS) $(DESTDIR)$(bindir)

installdirs:
	mkdir -p $(DESTDIR)$(bindir)

.PHONY: all clean distclean dist install installdirs
