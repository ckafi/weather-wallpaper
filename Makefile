SHELL = /bin/zsh
cachedir = ~/.cache/wallpaper/

all: wallpaper

wallpaper: wallpaper.nim
	nim compile -d:release --opt:size wallpaper.nim

.PHONY : install
install:
	mkdir -p $(cachedir) 
	cp wallpaper_blank.png $(cachedir)
	cp wallpaper ~/bin/

.PHONY : clean
clean:
	-rm wallpaper
	-rm text.png
	-rm result.png
	-rm -r nimcache
