PREFIX = /usr
BIN = /bin
DATA = /share
LICENSES = $(DATA)/licenses
COMMAND = bfind
PKGNAME = bfind

PY3_SHEBANG = /usr/bin/env/ python3


.PHONY: all
all: cmd

.PHONY: cmd
cmd: bfind

bfind: src/bfind.py
	cp "$<" "$@"
	sed -i 's:/usr/bin/env/ python3:$(PY3_SHEBANG):' "$@"


.PHONY: install
install: install-cmd install-license

.PHONY: install-cmd
install-cmd: bfind
	install -d -- "$(DESTDIR)$(PREFIX)$(BIN)"
	install -m755 -- bfind "$(DESTDIR)$(PREFIX)$(BIN)/$(COMMAND)"

.PHONY: install-license
install-license:
	install -d -- "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)"
	install -m644 -- COPYING LICENSE "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)"

.PHONY: uninstall
uninstall:
	-rm -- "$(DESTDIR)$(PREFIX)$(BIN)/$(COMMAND)"
	-rm -- "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)/COPYING"
	-rm -- "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)/LICENSE"
	-rm -d -- "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)"


.PHONY: clean
clean:
	-rm -- bfind

