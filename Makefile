# This makefile contains only one rule but we could
# add more. Fx. for document generation or for testing

# This rule will install libpothole to your nimble directory.
# Hopefully, your nimble dir is the same one as this:
install:
	if [ -d "~/.nimble/pkgs/libpothole-0.2.0/" ]; then \
		rm -rf "~/.nimble/pkgs/libpothole-0.2.0/"; \
	fi
	mkdir ~/.nimble/pkgs/libpothole-0.2.0/
	cp -r pothole/ ~/.nimble/pkgs/libpothole-0.2.0/