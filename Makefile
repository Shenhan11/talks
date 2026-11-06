DECKS := snow_corp_cncf kcd_vietnam coscup_2026 ossummit_korea hitcon_lightning hami_cross_platform_observability ossummit_europe_agents gpu_workshop
HTMLS := $(addprefix dist/,$(addsuffix .html,$(DECKS)))
PDFS  := $(HTMLS:.html=.pdf)
TAG   ?= v$(shell date +%Y.%m.%d)

all: $(HTMLS)

pdf: $(PDFS)

release: pdf
	gh release create $(TAG) $(PDFS) assets/demo/llm_test.mp4 --generate-notes

dist/%.html: %.deck.md
	@mkdir -p dist
	pdm run slidr $<

dist/%.pdf: %.deck.md
	@mkdir -p dist
	pdm run slidr --optimize-images --pdf $<

watch-%: %.deck.md
	pdm run slidr -w $<

clean:
	rm -rf dist/

.PHONY: all pdf release clean watch-%
