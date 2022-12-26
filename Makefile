# A sane rational Makefile for a sane rational project.
# no need for automake, autoconf or whatever
# it is you nerds come up with these days
SRCDIR=src
BUILDDIR=build
CC=nim
CP=cp -rv
CPRODFLAGS=--app:console -d:release --dynlibOverride:ssl --opt:speed --threads:off --stackTrace:on 
CSAFEFLAGS=$(CPRODFLAGS) -d:safe # Experimenting with Memory safety in Nim, do not use.
CDEBFLAGS=--app:console -d:debug -d:ssl --threadAnalysis:off --threads:on --opt:speed --stackTrace:on 

build: clean
	$(CC) c $(CPRODFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim

.SILENT: clean test build copystuff
.PHONY: clean test copystuff

all: copystuff build clean

clean:
	echo "Cleaning up build folder if it exists..."
	if [ -d "$(BUILDDIR)" ]; then \
		rm -rf "$(BUILDDIR)"; \
	fi
	mkdir "$(BUILDDIR)"

copystuff: clean
	cp pothole.conf $(BUILDDIR)/pothole.conf
	cp LICENSE $(BUILDDIR)/LICENSE

debug: copystuff clean
	$(CC) c $(CDEBFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim 

test: copystuff debug clean
	cd "$(BUILDDIR)"; ./pothole;

# Experimenting with Memory safety in Nim
# This is not useful for production and it might actually cause
# Bugs in production builds
safe: copystuff clean
	$(CC) c $(CSAFEFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim

rtest: copystuff
	echo "Compiling pothole..."
	$(CC) r $(CDEBFLAGS) $(SRCDIR)/pothole.nim
