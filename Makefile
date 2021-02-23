.POSIX:

CONFIGFILE = config.mk
include $(CONFIGFILE)


all: bfind

bfind.o: bfind.c arg.h
	$(CC) -c -o $@ bfind.c $(CPPFLAGS) $(CFLAGS)

bfind: bfind.o
	$(CC) -o $@ bfind.o $(LDFLAGS)

install: bfind
	mkdir -p -- "$(DESTDIR)$(PREFIX)/bin"
	mkdir -p -- "$(DESTDIR)$(MANPREFIX)/man1"
	cp -- bfind "$(DESTDIR)$(PREFIX)/bin/"
	cp -- bfind.1 "$(DESTDIR)$(MANPREFIX)/man1/"

uninstall:
	-rm -f -- "$(DESTDIR)$(PREFIX)/bin/bfind"
	-rm -f -- "$(DESTDIR)$(MANPREFIX)/man1/bfind.1"

clean:
	-rm -rf -- bfind *.o

.PHONY: all install uninstall clean
