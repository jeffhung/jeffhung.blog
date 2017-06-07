
BUNDLE_PATH = .vendor
BUNDLE      = $(if $(shell which bundle),bundle,\
                   $(error "Please install 'bundler' first: `brew gem install bundler`."))

.PHONY: jekyll-help
jekyll-help:
	@echo "Usage: make [ TARGET ... ]";
	@echo "";
	@echo "These jekyll-* make targets help you manage a Jekyll site.";
	@echo "";
	@echo "  jekyll-help   - show this help message";
	@echo "  jekyll-init   - bootstrap the jekyll site in this folder";
	@echo "  jekyll-clean  - removes site output and metadata file without building";
	@echo "  jekyll-purge  - purge jekyll site in this folder including data";
	@echo "  jekyll-build  - build the jekyll site in the _site folder";
	@echo "  jekyll-serve  - run the jekyll development server in local";
	@echo "";

.PHONY: jekyll-init
jekyll-init:
	[ -f Gemfile ] || cp jekyll.gemfile Gemfile;
	$(BUNDLE) install --path=$(BUNDLE_PATH)
	$(BUNDLE) exec jekyll new --force .

.PHONY: jekyll-clean
jekyll-clean:
	$(BUNDLE) exec jekyll clean

.PHONY: jekyll-purge
jekyll-purge: jekyll-clean
	rm -fr $(BUNDLE_PATH)
	rm -f  Gemfile.lock
	rm -fr .bundle
	rm -f  .gitignore
	rm -fr .sass-cache
	@echo "===> Note that all data will be cleaned.";
	rm -f  _config.yml
	rm -fr _posts
	rm -fr _site
	rm -f  about.md
	rm -f  index.md

.PHONY: jekyll-build
jekyll-build:
	$(BUNDLE) exec jekyll build

.PHONY: jekyll-serve
jekyll-serve: jekyll-build
	$(BUNDLE) exec jekyll serve

