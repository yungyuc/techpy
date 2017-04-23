SHELL := bash

# Outside control.
NUM ?= 3 # For LaTeX to correctly cross-reference.  To save time, use 1.
VERBOSE ?= 1

ifeq ($(VERBOSE),0)
	CMDLOG_REDIRECT := > /dev/null
	PSTAKE := ./pstake.py -q
else
	CMDLOG_REDIRECT := >&1
	PSTAKE := ./pstake.py
endif

# Environmental setting.
UNAME_CACHE := $(shell uname -s)
ifeq ($(UNAME_CACHE),Darwin)
	GVIM=mvim
	PDFVIEW=open -a skim
endif # FIXME: other platform?

# Build setting.
MAIN_FN := tppy
EPS_DIR := eps
SCHEMATIC_DIR := schematic
LATEX_DERIVED_EXT := toc glsdefs aux log out dvi ps pdf
NOWDATE := $(shell date +"%Y%m%d")
NOWID := $(shell git rev-parse --short HEAD)
HANDOVER_DIR := handover
HANDOVER_FN = $(HANDOVER_DIR)/$(basename $<).$(NOWDATE).$(NOWID).pdf

# Targets.
ALL_TEX = $(wildcard $(SCHEMATIC_DIR)/*.tex)
ALL_EPS = $(patsubst $(SCHEMATIC_DIR)/%.tex,$(EPS_DIR)/%.eps,$(ALL_TEX))
ALL_SRC = $(MAIN_FN).tex $(ALL_TEX)

.PHONY: default
default: pdf

$(EPS_DIR)/%.eps: $(SCHEMATIC_DIR)/%.tex Makefile pstake.py
	mkdir -p $(EPS_DIR)
	$(PSTAKE) $< $@

$(MAIN_FN).pdf: $(MAIN_FN).tex bibliography.bib $(ALL_EPS) Makefile
	@echo "Having EPS files: $(ALL_EPS)"
	num=1 ; while [[ $$num -le $(NUM) ]] ; do \
		xelatex -shell-escape $< 2>&1 | tee $@.$$num.cmd.log $(CMDLOG_REDIRECT) ; \
		bibtex $(basename $<) 2>&1 | tee $@.$$num.bibtex.log $(CMDLOG_REDIRECT) ; \
		(( num = num + 1 )) ; \
	done

.PRECIOUS: %.pdf

.PHONY: pdf
pdf: $(MAIN_FN).pdf

.PHONY: ho
ho: handover

.PHONY: handover
handover: $(MAIN_FN).pdf
	@echo "Generating today's PDF: $(HANDOVER_FN)"
	mkdir -p $(HANDOVER_DIR)
	cp -f $< $(HANDOVER_FN)

.PHONY: pdfview
pdfview:
	$(PDFVIEW) $(MAIN_FN).pdf

.PHONY: pv
pv: pdfview

.PHONY: fun
fun:
	$(GVIM) Makefile $(ALL_SRC) -p -c "set lines=999"
	$(PDFVIEW) $(MAIN_FN).pdf

.PHONY: clean
clean:
	rm -f $(EPS_DIR)/* *.cmd.log \
		$(foreach ext,$(LATEX_DERIVED_EXT),$(MAIN_FN).$(ext))

.PHONY: list
list:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | xargs

# vim: set sw=8 ts=8 noet:
