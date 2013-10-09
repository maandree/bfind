PY3_SHEBANG = /usr/bin/env/ python3


.PHONY: all
all: bfind

bfind: src/bfind.py
	cp "$<" "$@"
	sed -i 's:/usr/bin/env/ python3:$(PY3_SHEBANG):' "$@"


.PHONY: clean
clean:
	-rm -- bfind

