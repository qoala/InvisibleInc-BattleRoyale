#
# To get started, copy makeconfig.example.mk as makeconfig.mk and fill in the appropriate paths.
#
# build: Build all the zips and kwads
# install: Copy mod files into a local installation of Invisible Inc
# rar: Update the pre-built rar
#

include makeconfig.mk
.SECONDEXPANSION:

.PHONY: build install clean distclean

ensuredir = @mkdir -p $(@D)

files := modinfo.txt scripts.zip gui.kwad images.kwad
outfiles := $(addprefix out/, $(files))
installfiles := $(addprefix $(INSTALL_PATH)/, $(files))

ifneq ($(INSTALL_PATH2),)
	installfiles += $(addprefix $(INSTALL_PATH2)/, $(files))
endif

build: $(outfiles)
install: build $(installfiles)

$(installfiles): %: out/$$(@F)
	$(ensuredir)
	cp $< $@

clean:
	rm out/*

distclean:
	rm -f $(INSTALL_PATH)/*.kwad $(INSTALL_PATH)/*.zip
ifneq ($(INSTALL_PATH2),)
	rm -f $(INSTALL_PATH2)/*.kwad $(INSTALL_PATH2)/*.zip
endif


out/modinfo.txt: modinfo.txt
	$(ensuredir)
	cp modinfo.txt out/modinfo.txt

#
# kwads and contained files
#

# anims := $(patsubst %.anim.d,%.anim,$(shell find anims -type d -name "*.anim.d"))
#
# $(anims): %.anim: $(wildcard %.anim.d/*.xml $.anim.d/*.png)
# 	cd $*.anim.d && zip ../$(notdir $@) *.xml *.png

gui := $(wildcard gui/**/*.png)
images := $(wildcard images/**/*.png)

out/images.kwad out/gui.kwad: $(images) $(gui)
	$(ensuredir)
	$(KWAD_BUILDER) -i build.lua -o out

#
# scripts
#

out/scripts.zip: $(shell find scripts -type f -name "*.lua")
	$(ensuredir)
	cd scripts && zip -r ../$@ . -i '*.lua'
