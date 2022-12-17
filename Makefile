# A sane rational Makefile for a sane rational project.
# no need for automake, autoconf or whatever
# it is you nerds come up with these days
SRCDIR=src
BUILDDIR=build
CC=nim
CP=cp -rv
CPRODFLAGS=--app:console -d:release --opt:speed --threads:on --stackTrace:on 
CDEBFLAGS=--app:console --opt:speed --threads:on --stackTrace:on 

build: clean
	$(CC) c $(CPRODFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim

.SILENT: clean test build
.PHONY: clean test

all: build clean

clean:
	echo "Cleaning up build folder if it exists..."
	if [ -d "$(BUILDDIR)" ]; then \
		rm -rf "$(BUILDDIR)"; \
	fi
	mkdir "$(BUILDDIR)"

debug: clean
	$(CC) c $(CDEBFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim 

test:
	echo "Compiling pothole..."
	$(CC) r $(CDEBFLAGS) $(SRCDIR)/pothole.nim