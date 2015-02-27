all: svg2hack

cmds:
	bash cmds.sh

svg2hack:
	cat drawing.svg | perl  -pe 's/rx="\d+"/rx="20"/' | perl  -pe 's/ry="\d+"/ry="20"/'  > e.svg; inkscape -E e.eps e.svg
