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
	cp $(SRCDIR)/pothole.conf $(BUILDDIR)/pothole.conf
	cp $(SRCDIR)/pothole.example.conf $(BUILDDIR)/pothole.example.conf
	cp LICENSE $(BUILDDIR)/LICENSE

debug: clean
	$(CC) c $(CDEBFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim 

test: copystuff
	echo "Compiling pothole..."
	$(CC) r $(CDEBFLAGS) $(SRCDIR)/pothole.nim
