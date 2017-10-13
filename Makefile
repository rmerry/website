# Content

AUTHOR_NAME = "Richard Merry"
AUTHOR_EMAIL = "richard@bitsociety.uk"
SITE_TITLE = "bitsociety"
SITE_TAGLINE = "My website on programming and other things"
LOCALE = "en_GB.utf-8"

POSTS_PER_PAGE = 10
POSTS_PER_PAGE_ATOM = 10

POSTS = \
	a_quick_delve_into_goroutines_and_channels\
	creating_a_job_scheduler_in_go\
	$(NULL)

PAGES = \
	about \
	static_html_code_highligher \
	$(NULL)

ASSETS = $(shell find assets/ -type f)

# Arguments

BLOGC ?= $(shell which blogc)
BLOGC_RUNSERVER ?= $(shell which blogc-runserver 2> /dev/null)
ENTR ?= $(shell which entr 2> /dev/null)
MKDIR ?= $(shell which mkdir)
CP ?= $(shell which cp)

BLOGC_RUNSERVER_HOST ?= 127.0.0.1
BLOGC_RUNSERVER_PORT ?= 8080

OUTPUT_DIR ?= _build
BASE_DOMAIN ?= http://bitsociety.co.uk
BASE_URL ?= 

DATE_FORMAT = "%A, %d %B %Y"
DATE_FORMAT_ATOM = "%A, %d %B %Y"

BLOGC_COMMAND = \
	LC_ALL=$(LOCALE) \
	$(BLOGC) \
		-D AUTHOR_NAME=$(AUTHOR_NAME) \
		-D AUTHOR_EMAIL=$(AUTHOR_EMAIL) \
		-D SITE_TITLE=$(SITE_TITLE) \
		-D SITE_TAGLINE=$(SITE_TAGLINE) \
		-D BASE_DOMAIN=$(BASE_DOMAIN) \
		-D BASE_URL=$(BASE_URL) \
	$(NULL)


# Rules

POSTS_LIST = $(addprefix content/post/, $(addsuffix .txt, $(POSTS)))
PAGES_LIST = $(addprefix content/, $(addsuffix .txt, $(PAGES)))

LAST_PAGE = $(shell $(BLOGC_COMMAND) \
	-D FILTER_PAGE=1 \
	-D FILTER_PER_PAGE=$(POSTS_PER_PAGE) \
	-p LAST_PAGE \
	-l \
	$(POSTS_LIST))

ALL_LIST = \
	$(POSTS_LIST) \
	$(PAGES_LIST) \
	$(ASSETS) \
	templates/main.tmpl \
	templates/atom.tmpl \
	Makefile \
	$(NULL)

all: \
	$(OUTPUT_DIR)/index.html \
	$(OUTPUT_DIR)/atom.xml \
	$(addprefix $(OUTPUT_DIR)/, $(ASSETS)) \
	$(addprefix $(OUTPUT_DIR)/post/, $(addsuffix /index.html, $(POSTS))) \
	$(addprefix $(OUTPUT_DIR)/, $(addsuffix /index.html, $(PAGES))) \
	$(addprefix $(OUTPUT_DIR)/page/, $(addsuffix /index.html, \
		$(shell for i in $(shell seq 1 $(LAST_PAGE)); do echo $$i; done)))

$(OUTPUT_DIR)/index.html: $(POSTS_LIST) templates/main.tmpl Makefile
	$(BLOGC_COMMAND) \
		-D DATE_FORMAT=$(DATE_FORMAT) \
		-D FILTER_PAGE=1 \
		-D FILTER_PER_PAGE=$(POSTS_PER_PAGE) \
		-D MENU=Home \
		-D DESCRIPTION=Home \
		-l \
		-o $@ \
		-t templates/main.tmpl \
		$(POSTS_LIST)

$(OUTPUT_DIR)/page/%/index.html: $(POSTS_LIST) templates/main.tmpl Makefile
	$(BLOGC_COMMAND) \
		-D DATE_FORMAT=$(DATE_FORMAT) \
		-D FILTER_PAGE=$(shell echo $@ | sed -e 's,^$(OUTPUT_DIR)/page/,,' -e 's,/index\.html$$,,')\
		-D FILTER_PER_PAGE=$(POSTS_PER_PAGE) \
		-D MENU=blog \
		-l \
		-o $@ \
		-t templates/main.tmpl \
		$(POSTS_LIST)

$(OUTPUT_DIR)/atom.xml: $(POSTS_LIST) templates/atom.tmpl Makefile
	$(BLOGC_COMMAND) \
		-D DATE_FORMAT=$(DATE_FORMAT_ATOM) \
		-D FILTER_PAGE=1 \
		-D FILTER_PER_PAGE=$(POSTS_PER_PAGE_ATOM) \
		-l \
		-o $@ \
		-t templates/atom.tmpl \
		$(POSTS_LIST)

IS_POST = 0

$(OUTPUT_DIR)/about/index.html: MENU = about
$(OUTPUT_DIR)/things/index.html: MENU = things
$(OUTPUT_DIR)/static_html_code_highligher/index.html: MENU = syntax

$(OUTPUT_DIR)/post/%/index.html: MENU = blog
$(OUTPUT_DIR)/post/%/index.html: IS_POST = 1

$(OUTPUT_DIR)/%/index.html: content/%.txt templates/main.tmpl Makefile
	$(BLOGC_COMMAND) \
		-D DATE_FORMAT=$(DATE_FORMAT) \
		-D MENU=$(MENU) \
		$(shell test "$(IS_POST)" -eq 1 && echo -D IS_POST=1) \
		-o $@ \
		-t templates/main.tmpl \
		$<

$(OUTPUT_DIR)/assets/%: assets/% Makefile
	$(MKDIR) -p $(dir $@) && \
		$(CP) $< $@

ifneq ($(BLOGC_RUNSERVER),)
.PHONY: serve
serve: all
	$(BLOGC_RUNSERVER) \
		-t $(BLOGC_RUNSERVER_HOST) \
		-p $(BLOGC_RUNSERVER_PORT) \
		$(OUTPUT_DIR)
endif

ifneq ($(ENTR),)
.PHONY: reload
reload:
	for i in $(ALL_LIST); do echo $$i; done | $(ENTR) -r $(MAKE) serve
endif

clean:
	rm -rf "$(OUTPUT_DIR)"

.PHONY: all clean
