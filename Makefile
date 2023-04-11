install:
	if [ -d "~/.nimble/pkgs/libpothole-0.2.0/" ]; then \
		rm -rf "~/.nimble/pkgs/libpothole-0.2.0/"; \
	fi
	mkdir ~/.nimble/pkgs/libpothole-0.2.0/
	cp -r pothole/ ~/.nimble/pkgs/libpothole-0.2.0/

style:
	sass --sourcemap=none --style=compressed style.scss htmldocs/nimdoc.out.css

test:
	nimble docs
	ls style.scss | entr make style

.SILENT: install
.PHONY: install