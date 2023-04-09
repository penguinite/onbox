install:
	if [ -d "~/.nimble/pkgs/libpothole-0.2.0/" ]; then \
		rm -rf "~/.nimble/pkgs/libpothole-0.2.0/"; \
	fi
	mkdir ~/.nimble/pkgs/libpothole-0.2.0/
	cp -r pothole/ ~/.nimble/pkgs/libpothole-0.2.0/

.SILENT: install
.PHONY: install