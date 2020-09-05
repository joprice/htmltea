
all: run test-svg

run:
	 @cat data/test.html | dune exec bin/main.exe https://github.com/rgrinberg/curly

test-svg:
	 @cat data/svg.html | dune exec bin/main.exe

build-nix:
	nix-build -A htmltea

resolve:
	nix-shell -A resolve ./default.nix

dep-graph:
	 nix-store -q --graph result

watch:
	dune build --watch

upload-deps:
	nix-store -qR --include-outputs `nix-instantiate shell.nix` | grep -v htmltea | cachix push joprice
