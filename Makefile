PREFIX = /usr
BIN = /bin
DATA = /share
LICENSES = $(DATA)/licenses
COMMAND = bfind
PKGNAME = bfind

PY3_SHEBANG = /usr/bin/env/ python3


.PHONY: all
all: cmd doc

.PHONY: cmd
cmd: bfind

.PHONY: doc
doc: info

.PHONY: info
info: bfind.info.gz

%.info.gz: info/%.texinfo.install
	makeinfo "$<"
	gzip -9 -f "$*.info"

info/%.texinfo.install: info/%.texinfo
	cp "$<" "$@"
	sed -i 's:^@set COMMAND bfind:@set COMMAND $(COMMAND):g' "$@"

bfind: src/bfind.py
	cp "$<" "$@"
	sed -i 's:/usr/bin/env/ python3:$(PY3_SHEBANG):' "$@"


.PHONY: install
install: install-core install-doc

.PHONY: install-core
install-core: install-cmd install-license

.PHONY: install-cmd
install-cmd: bfind
	install -d -- "$(DESTDIR)$(PREFIX)$(BIN)"
	install -m755 -- bfind "$(DESTDIR)$(PREFIX)$(BIN)/$(COMMAND)"

.PHONY: install-license
install-license:
	install -d -- "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)"
	install -m644 -- COPYING LICENSE "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)"

.PHONY: install-doc
install-doc: install-info

.PHONY: install-info
install-info: bfind.info.gz
        install -dm755 -- "$(DESTDIR)$(PREFIX)$(DATA)/info"
        install -m644 bfind.info.gz -- "$(DESTDIR)$(PREFIX)$(DATA)/info/$(PKGNAME).info.gz"


.PHONY: uninstall
uninstall:
	-rm -- "$(DESTDIR)$(PREFIX)$(BIN)/$(COMMAND)"
	-rm -- "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)/COPYING"
	-rm -- "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)/LICENSE"
	-rm -d -- "$(DESTDIR)$(PREFIX)$(LICENSES)/$(PKGNAME)"
	-rm -- "$(DESTDIR)$(PREFIX)$(DATA)/info/$(PKGNAME).info.gz"


.PHONY: clean
clean:
	-rm -- bfind bfind.info.gz info/*.install

