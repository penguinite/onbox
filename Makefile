# A sane rational Makefile for a sane rational project.
# no need for automake, autoconf or whatever
# it is you nerds come up with these days
SRCDIR=src
BUILDDIR=build
CC=nim

# Use this as a base for other flags.
BASEFLAGS=--app:console --threads:on --stackTrace:on

## Various preset flags.
# Debug flags
DEBFLAGS=$(BASEFLAGS) -d:debug
# Release flags
PRODFLAGS=$(BASEFLAGS) -d:release
# Safe flags (Read https://forum.nim-lang.org/t/1961#12174 before using)
SAFEFLAGS=$(BASEFLAGS) -d:safe 
# Danger flags (Do not use for production builds)
DANGERFLAGS=$(BASEFLAGS) -d:danger

# Build release as default 
all: copystuff release clean

.SILENT: clean test copystuff 
.PHONY: clean test


# Clean target that removes the builddir and other useless dirs.
clean:
	echo "Cleaning up useless folders if they exist..."
	if [ -d "$(BUILDDIR)" ]; then \
		rm -rf "$(BUILDDIR)"; \
	fi
	if [ -d "static/" ]; then \
		rm -rf "static"; \
	fi
	if [ -d "uploads/" ]; then \
		rm -rf "uploads"; \
	fi
	if [ -d "blogs/" ]; then \
		rm -rf "blogs"; \
	fi

# This copies stuff for debug & release builds.
# Like the config file and the LICENSE.
copystuff: clean
	echo "Copying files to build dir..."
	if [ ! -d "$(BUILDDIR)" ]; then \
		mkdir "$(BUILDDIR)"; \
	fi
	cp pothole.conf $(BUILDDIR)/pothole.conf
	cp LICENSE $(BUILDDIR)/LICENSE

# Run whatever binary we have.
test:
	echo "Testing built Pothole..."
	cd "$(BUILDDIR)"; ./pothole;

## Preset build targets
# Debug settings...
debug: copystuff clean 
	$(CC) c $(DEBFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim 

# Release settings... (Aka. what you should be using)
release: copystuff clean
	$(CC) c $(PRODFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim
	
# Safe settings... Don't use this unless you're experimenting
safe: copystuff clean
	$(CC) c $(SAFEFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim

# Danger settings... Don't use this at all.
danger: copystuff clean
	$(CC) c $(DANGERFLAGS) -o:$(BUILDDIR)/pothole $(SRCDIR)/pothole.nim
	
## Test targets
# Compiles a binary with debug settings and runs it.
test_debug: debug test

# Compiles a binary with release settings and runs it.
test_release: release test 

# Compiles a binary with safe settings and runs it.
# Note: For -d:safe to work, it requires a specical config
# Check this link: https://forum.nim-lang.org/t/1961#12174 and go to footnote 4.
# This is not recommended for production builds
test_safe: safe test 

# Compiles a binary with -d:danger and runs it.
# Note: Don't use this for production builds.
test_danger: danger test 

# Run whaetever control program we have.
testctl:
	echo "Testing control program"
	cd "$(BUILDDIR)"; ./potholectl;

## Control command section
debugctl: copystuff clean
	$(CC) c $(DEBFLAGS) -o:$(BUILDDIR)/potholectl $(SRCDIR)/potholectl.nim 

releasectl: copystuff clean
	$(CC) c $(PRODFLAGS) -o:$(BUILDDIR)/potholectl $(SRCDIR)/potholectl.nim 

testctl_debug: debugctl testctl

testctl_release: releasectl testctl