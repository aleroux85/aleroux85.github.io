include make/tpl.mk

# Three mode flags are used to determine a build. XXX means no flags are enabled.
#
# mode flags:
# - enable unit testing (T)
# - readable web content (R)
# - types of back-end (G|S)

.PHONY: dev TRX

dev TRX: ui/home.html ui/dist/index.css ui/dist/index.js
	@mkdir -p ui/dist
	@sed -i '/\/\/online-start$$/,/\/\/online-end$$/d' ui/dist/index.js
	@sed -i '/\/\/online$$/d' ui/dist/index.js
	$(call compose,ui/home.html,make/web.map,ui/dist/index.html)
	@cp ui/unlog.html ui/dist/unlog.html
	@cp ui/contact.html ui/dist/contact.html
	@cp ui/articles/* ui/dist/
	@cp ui/robots.staging.txt ui/dist/robots.txt
	@# Staging must never be indexed. Inject a noindex tag into every built
	@# page (skipping any that already declare one) as a second layer behind
	@# the Disallow-all robots.txt. This is applied only by `make dev`, so the
	@# production build (`make prd`) never carries it.
	@for f in ui/dist/*.html; do \
		grep -q 'name="robots"' "$$f" || \
		sed -i 's#\(<title>[^<]*</title>\)#\1\n  <meta name="robots" content="noindex, nofollow" />#' "$$f"; \
	done
	@echo "Built local dev version"

.PHONY: prd TRS

prd TRS: ui/home.html ui/dist/index.css ui/dist/index.js
	@mkdir -p ui/dist
	$(call compose,ui/home.html,make/web.map,ui/dist/index.html)
	@cp ui/unlog.html ui/dist/unlog.html
	@cp ui/contact.html ui/dist/contact.html
	@cp ui/articles/* ui/dist/
	@cp ui/robots.prod.txt ui/dist/robots.txt
	@cp ui/sitemap.xml ui/dist/sitemap.xml
	@echo "anroleroux.co.za" > ui/dist/CNAME
	@echo "Built local dev version → dist/index.html"

ui/dist/index.css: ui/root.css ui/almanac.css ui/cosmos.css $(wildcard comps/*.css)
	@mkdir -p ui/dist
	$(call compose,ui/root.css,make/web.map,ui/dist/index.css)

ui/dist/index.js: ui/root.js $(wildcard comps/*.js)
	@mkdir -p ui/dist
	$(call compose,ui/root.js,make/web.map,ui/dist/index.js)

.PHONY: clean c

clean c:
	rm -rf ui/dist
