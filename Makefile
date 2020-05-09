
all: run test-svg

run:
	 @cat data/test.html | dune exec bin/main.exe

test-svg:
	 @cat data/svg.html | dune exec bin/main.exe
