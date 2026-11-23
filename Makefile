############################
# Usage
# make         # converts all src/*.md files to publish/*.pdf files
# make clean   # cleans up publish/*.pdf artifacts
############################

all:

############################
# Common
############################

PANDOC = pandoc

PUBLISH_DIR = publish
SRC_DIR = src
IMAGES_DIR = images
COMMON_DIR = common

############################
# Targets
############################

SRC  = $(wildcard $(SRC_DIR)/*.md)
PDF  = $(SRC:.md=.pdf)
PDF_DARK = $(PDF:.pdf=-dark.pdf)

PDF_PUBLISH = $(PDF:$(SRC_DIR)/%=$(PUBLISH_DIR)/%) #$(PDF_DARK:$(SRC_DIR)/%=$(PUBLISH_DIR)/%)
PDF_NAMES = $(PDF:$(SRC_DIR)/%.pdf=%)

PNG_ROOT = $(wildcard $(IMAGES_DIR)/*.png)
PNG_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.png))
PNG = $(PNG_ROOT) $(PNG_TARGET)

SVG_ROOT = $(wildcard $(IMAGES_DIR)/*.svg)
SVG_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.svg))
SVG_PDF_ROOT = $(SVG_ROOT:.svg=.pdf)
SVG_PDF_TARGET = $(SVG_TARGET:.svg=.pdf)
SVG_PDF = $(SVG_PDF_ROOT) $(SVG_PDF_TARGET)

DOT_ROOT = $(wildcard $(IMAGES_DIR)/*.gv)
DOT_TARGET = $(foreach NAME,$(PDF_NAMES),$(wildcard $(IMAGES_DIR)/$(NAME)/*.gv))
DOT_PDF_ROOT = $(DOT_ROOT:.gv=.pdf)
DOT_PDF_TARGET = $(DOT_TARGET:.gv=.pdf)
DOT_PDF = $(DOT_PDF_ROOT) $(DOT_PDF_TARGET)

############################
# Goals
############################

.PHONY: all clean pdf
.DEFAULT_GOAL := all

all: pdf

publish: $(PDF_PUBLISH)
pdf:  $(PDF) #$(PDF_DARK)

clean: 
	@echo "Cleaning up..."
	rm -rvf $(PDF) $(SVG_PDF) $(DOT_PDF) $(BUILD_DIR)

############################
# Publish patterns
############################

$(PDF_PUBLISH): $(PUBLISH_DIR)/%.pdf: $(SRC_DIR)/%.pdf
	@mkdir -p $(@D)
	cp $< $@

############################
# Pandoc + LuaLaTeX patterns
############################
# pandoc's PDF pipeline runs the LaTeX engine up to 4 times: it reruns on
# any "Warning: ... Rerun" log line, and it forces 3 runs whenever a .toc
# file exists ("TOC is present", jgm/pandoc#10308) -- beamer writes .toc
# for every deck with sections, even with no TOC slide. ~51s for a 47-page
# deck. One lualatex pass produces a pixel-identical PDF in ~12s, so we go
# through an intermediate .tex and run the engine once.

PANDOC_COMMON = $(COMMON_DIR)/pres.yaml -H $(COMMON_DIR)/pres-preamble.tex \
	--listings --template $(COMMON_DIR)/pres-template.tex --slide-level=1

BUILD_DIR = build

$(BUILD_DIR)/%.tex: $(SRC_DIR)/%.md common/pres.yaml common/pres-preamble.tex common/pres-template.tex
	@mkdir -p $(@D)
	$(PANDOC) $(PANDOC_COMMON) -t beamer $< -o $@

$(PDF): $(SRC_DIR)/%.pdf: $(BUILD_DIR)/%.tex
	cd $(BUILD_DIR) && lualatex -interaction=nonstopmode $*.tex > /dev/null
	cp $(BUILD_DIR)/$*.pdf $@

$(BUILD_DIR)/%-dark.tex: $(SRC_DIR)/%.md common/pres.yaml common/pres-preamble.tex common/pres-template.tex
	@mkdir -p $(@D)
	$(PANDOC) $(PANDOC_COMMON) -t beamer --variable darkmode=true $< -o $@

$(PDF_DARK): $(SRC_DIR)/%-dark.pdf: $(BUILD_DIR)/%-dark.tex
	cd $(BUILD_DIR) && lualatex -interaction=nonstopmode $*-dark.tex > /dev/null
	cp $(BUILD_DIR)/$*-dark.pdf $@

############################
# Image patterns
############################

$(SVG_PDF): %.pdf: %.svg
	@# SELF_CALL is workaround for running inkscape in parallel
	@# See https://gitlab.com/inkscape/inkscape/-/issues/4716
	SELF_CALL=no inkscape -D $< -o $@


$(DOT_PDF): %.pdf: %.gv
	dot -Tpdf $< -o $@

############################
# Custom patterns
############################


TARGET_IMAGE_DEPS = $(filter $(IMAGES_DIR)/$*/%,$(DOT_PDF_TARGET) $(SVG_PDF_TARGET) $(PNG_TARGET))
ROOT_IMAGE_DEPS = $(filter $(IMAGES_DIR)/%,$(DOT_PDF_ROOT) $(SVG_PDF_ROOT) $(PNG_ROOT))

.SECONDEXPANSION:
$(PDF): $(SRC_DIR)/%.pdf: $(ROOT_IMAGE_DEPS) $(COMMON_PNG_IMAGE_DEPS) $$(TARGET_IMAGE_DEPS)
$(PDF_DARK): $(SRC_DIR)/%-dark.pdf: $(ROOT_IMAGE_DEPS) $(COMMON_PNG_IMAGE_DEPS) $$(TARGET_IMAGE_DEPS)

$(PDF) $(PDF_DARK): $(COMMON_DIR)/pres.yaml $(COMMON_DIR)/pres-preamble.tex $(COMMON_DIR)/pres-template.tex

