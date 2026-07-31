# HotelByte Blog Guidance

## Responsibility

This repository owns the Jekyll site at `blog.hotelbyte.com`: bilingual technical posts and whitepapers, topic hubs, layouts/includes, GitHub Pages configuration, and SEO/AEO discovery surfaces.

## Read Before Editing

- Start with `README.md`, `_config.yml`, and `Gemfile`.
- For posts, inspect a recent file under the matching `_posts/en/` or `_posts/zh/` collection and the relevant archive/series page.
- For layout or discovery work, read `_layouts/`, `_includes/ai-geo-head.html`, `_data/ai_geo.yml`, `llms.txt`, `ai-index.json`, `robots.txt`, and `test/seo_geo_test.rb`.
- For publishing behavior, read `.github/workflows/jekyll.yml`; pushes to `main` build and deploy GitHub Pages.
- Treat `docs/twitter-technical-promotion-tracker.md` and `docs/whitepaper-content-matrix.md` as separate editorial planning tracks.

## Boundaries

- New posts use `YYYY-MM-DD-title.md` with valid YAML front matter. Place language-specific posts in `_posts/en/` or `_posts/zh/` and set/retain the correct language and permalink behavior.
- Keep technical and product claims evidence-backed. Do not present roadmap ideas, generated examples, or inferred implementation details as shipped HotelByte behavior.
- Preserve canonical public URLs. When a priority route or topic hub changes, reconcile navigation links, `_data/ai_geo.yml`, `llms.txt`, `ai-index.json`, robots/sitemap declarations, and tests as applicable.
- Keep shared layout includes for canonical, Open Graph, Twitter, JSON-LD, language alternate, and AEO metadata intact unless the task intentionally replaces them.
- Do not copy secrets, private customer data, internal tokens, or unredacted production evidence into posts, front matter, examples, trackers, or generated site files.
- Do not edit generated `_site/` output or vendor dependencies. Change Jekyll sources and rebuild.
- Do not push directly to `main` or trigger publication unless the task explicitly requests publishing.

## Smallest Real Verification

- Documentation or Markdown-only changes: `git diff --check`; also run the Jekyll build when front matter, Liquid, navigation, or public links changed.
- SEO/AEO, layout, topic-hub, discovery-file, or route changes: `bundle exec ruby test/seo_geo_test.rb` and `bundle exec jekyll build`.
- Post/front-matter changes: `bundle exec jekyll build`.
- Workflow or dependency changes: `bundle exec jekyll build`, plus inspect the affected `.github/workflows/jekyll.yml` or `Gemfile.lock` diff.
- Report the exact commands run. A local Jekyll build proves generation, not that GitHub Pages has deployed the new site.

## Code Review Rules

- Flag technical/product claims without a traceable source or claims that confuse planned, sample, or experimental behavior with production capability. Safe path: cite the evidence in the article or narrow the wording and state the gap.
- Flag route or topic-hub changes that leave AI discovery, navigation, canonical metadata, or SEO tests pointing at stale URLs. Safe path: update the affected source-of-truth files as one route change and run the SEO/GEO test.
- Flag bilingual pairs whose shared facts, product names, URLs, dates, or legal meaning diverge unintentionally. Safe path: keep factual assertions aligned while allowing natural language-specific prose.
- Flag front matter that breaks the configured language/permalink collections or publishes an unintended future-dated post. Safe path: validate the generated URL and build output deliberately.
- Flag removal of shared SEO/AEO includes from any layout without equivalent canonical, alternate-language, structured-data, and social metadata. Safe path: preserve the shared include or prove the replacement in tests and generated HTML.
