PREFIX = /usr
BIN = /bin
DATA = /share
BINDIR = $(PREFIX)/bin
DATADIR = $(PREFIX)/share
INFODIR = $(DATADIR)/info
DOCDIR = $(DATADIR)/doc
LICENSEDIR = $(DATADIR)/licenses

COMMAND = bfind
PKGNAME = bfind

PY3_SHEBANG = /usr/bin/env python3



.PHONY: default
default: cmd info

.PHONY: all
all: cmd doc

.PHONY: cmd
cmd: bin/bfind

bin/bfind: src/bfind.py
	@mkdir -p bin
	cp $< $@
	sed -i 's:/usr/bin/env/ python3:$(PY3_SHEBANG):' "$@"

.PHONY: doc
doc: info pdf dvi ps

.PHONY: info
info: bin/bfind.info
bin/%.info: doc/info/%.texinfo
	@mkdir -p bin
	$(MAKEINFO) $<
	mv $*.info $@

.PHONY: pdf
pdf: bin/bfind.pdf
bin/%.pdf: doc/info/%.texinfo
	@! test -d obj/pdf || rm -rf obj/pdf
	@mkdir -p bin obj/pdf
	cd obj/pdf && texi2pdf ../../"$<" < /dev/null
	mv obj/pdf/$*.pdf $@

.PHONY: dvi
dvi: bin/bfind.dvi
bin/%.dvi: doc/info/%.texinfo
	@! test -d obj/dvi || rm -rf obj/dvi
	@mkdir -p bin obj/dvi
	cd obj/dvi && $(TEXI2DVI) ../../"$<" < /dev/null
	mv obj/dvi/$*.dvi $@

.PHONY: ps
ps: bin/bfind.ps
bin/%.ps: doc/info/%.texinfo
	@! test -d obj/ps || rm -rf obj/ps
	@mkdir -p bin obj/ps
	cd obj/ps && texi2pdf --ps ../../"$<" < /dev/null
	mv obj/ps/$*.ps $@



.PHONY: install-default
install-default: install-core install-info

.PHONY: install
install: install-core install-doc

.PHONY: install-core
install-core: install-cmd install-license

.PHONY: install-cmd
install-cmd: bin/bfind
	install -dm755 -- "$(DESTDIR)$(BINDIR)"
	install -m755 --  $< "$(DESTDIR)$(BINDIR)/$(COMMAND)"

.PHONY: install-license
install-license:
	install -dm755 -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	install -m644 -- COPYING LICENSE "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"

.PHONY: install-doc
install-doc: install-info install-pdf install-dvi install-ps

.PHONY: install-info
install-info: bin/bfind.info
	install -dm755 -- "$(DESTDIR)$(INFODIR)"
	install -m644 $< -- "$(DESTDIR)$(INFODIR)/$(PKGNAME).info"

.PHONY: install-pdf
install-pdf: bin/bfind.pdf
	install -dm755 -- "$(DESTDIR)$(DOCDIR)"
	install -m644 $< -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).pdf"

.PHONY: install-dvi
install-dvi: bin/bfind.dvi
	install -dm755 -- "$(DESTDIR)$(DOCDIR)"
	install -m644 $< -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).dvi"

.PHONY: install-ps
install-ps: bin/bfind.ps
	install -dm755 -- "$(DESTDIR)$(DOCDIR)"
	install -m644 $< -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).ps"



.PHONY: uninstall
uninstall:
	-rm -- "$(DESTDIR)$(BINDIR)/$(COMMAND)"
	-rm -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/COPYING"
	-rm -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/LICENSE"
	-rmdir -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	-rm -- "$(DESTDIR)$(INFODIR)/$(PKGNAME).info"
	-rm -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).pdf"
	-rm -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).dvi"
	-rm -- "$(DESTDIR)$(DOCDIR)/$(PKGNAME).ps"



.PHONY: clean
clean:
	-rm -r obj bin

