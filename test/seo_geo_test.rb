require "minitest/autorun"
require "yaml"
require "json"

ROOT = File.expand_path("..", __dir__)

class SeoGeoTest < Minitest::Test
  def read(path)
    File.read(File.join(ROOT, path))
  end

  def test_ai_geo_data_describes_hotelbyte_entities_and_routes
    data = YAML.safe_load(read("_data/ai_geo.yml"))

    assert_equal "HotelByte", data.fetch("brand").fetch("name")
    assert_equal "https://blog.hotelbyte.com", data.fetch("brand").fetch("url")
    assert_includes data.fetch("audiences"), "travel technology leaders"
    assert_includes data.fetch("key_topics"), "hotel API aggregation"
    assert_includes data.fetch("priority_routes"), "/en/whitepapers/"
    assert_includes data.fetch("priority_routes"), "/zh/whitepapers/"

    aeo = data.fetch("agent_optimization")
    assert_equal "1.0", aeo.fetch("aeo_version")
    assert_includes aeo.fetch("agent_queries"), "How to integrate hotel APIs"
    assert aeo.fetch("answer_engine").size >= 3
  end

  def test_layouts_emit_ai_geo_head_metadata
    assert_includes read("_layouts/default.html"), "{% include ai-geo-head.html %}"
    assert_includes read("_layouts/home.html"), "{% include ai-geo-head.html %}"
    assert_includes read("_layouts/post.html"), "{% include ai-geo-head.html %}"

    include_body = read("_includes/ai-geo-head.html")
    assert_includes include_body, "application/ld+json"
    assert_includes include_body, "Organization"
    assert_includes include_body, "Blog"
    assert_includes include_body, "inLanguage"
    assert_includes include_body, "alternate"
    assert_includes include_body, "aeo-version"
    assert_includes include_body, "agent-summary"
    assert_includes include_body, "agent-queries"
    assert_includes include_body, "canonical"
    assert_includes include_body, "og:title"
    assert_includes include_body, "twitter:card"
    assert_includes include_body, "BreadcrumbList"
    assert_includes include_body, "FAQPage"
  end

  def test_llms_file_points_ai_crawlers_to_canonical_content
    llms = read("llms.txt")

    assert_includes llms, "# HotelByte Blog"
    assert_includes llms, "https://blog.hotelbyte.com/en/topics/hotel-api-integration/"
    assert_includes llms, "https://blog.hotelbyte.com/zh/topics/hotel-api-integration/"
    assert_includes llms, "https://openapi.hotelbyte.com"
    assert_includes llms, "https://blog.hotelbyte.com/en/whitepapers/"
    assert_includes llms, "https://blog.hotelbyte.com/zh/whitepapers/"
    assert_includes llms, "AI-Native Engineering Operating System"
    assert_includes llms, "Geographic Search"
    assert_includes llms, "Agent Engine Optimization"
    assert_includes llms, "AEO"
    assert_includes llms, "What is HotelByte?"
    assert_includes llms, "How does HotelByte handle hotel API integration?"
  end

  def test_ai_geo_routes_include_industry_topic_hubs
    data = YAML.safe_load(read("_data/ai_geo.yml"))
    routes = data.fetch("priority_routes")

    assert_includes routes, "/en/topics/hotel-api-integration/"
    assert_includes routes, "/zh/topics/hotel-api-integration/"
    assert_includes routes, "/en/topics/openapi-hotel-distribution/"
    assert_includes routes, "/zh/topics/openapi-hotel-distribution/"
  end

  def test_topic_hubs_target_hospitality_search_intent_and_openapi_docs
    english = read("en/topics/hotel-api-integration.md")
    chinese = read("zh/topics/hotel-api-integration.md")
    openapi = read("en/topics/openapi-hotel-distribution.md")

    assert_includes english, "hotel API integration"
    assert_includes english, "supplier direct connection"
    assert_includes english, "room mapping"
    assert_includes english, "FAQ"
    assert_includes chinese, "酒店 API 集成"
    assert_includes chinese, "供应商直连"
    assert_includes chinese, "房型映射"
    assert_includes openapi, "openapi.hotelbyte.com"
    assert_includes openapi, "Customer Certification"
    assert_includes openapi, "Error Handling"
  end

  def test_topic_hubs_are_linked_from_navigation_surfaces
    assert_includes read("en_series.md"), "/en/topics/hotel-api-integration/"
    assert_includes read("zh_series.md"), "/zh/topics/hotel-api-integration/"
    assert_includes read("en/index.md"), "/en/topics/openapi-hotel-distribution/"
    assert_includes read("index.md"), "/zh/topics/openapi-hotel-distribution/"
  end

  def test_ai_index_exposes_machine_readable_discovery_map
    source = read("ai-index.json")

    assert_includes source, "site.data.ai_geo"
    assert_includes source, "priority_routes"
    assert_includes source, "featured_content"
    assert_includes source, "agent_optimization"
    assert_includes read("llms.txt"), "https://blog.hotelbyte.com/ai-index.json"
  end

  def test_robots_allows_major_ai_crawlers_and_declares_sitemaps
    robots = read("robots.txt")

    %w[GPTBot ChatGPT-User ClaudeBot PerplexityBot Google-Extended].each do |crawler|
      assert_includes robots, "User-agent: #{crawler}"
    end

    assert_includes robots, "Sitemap: https://blog.hotelbyte.com/sitemap.xml"
    assert_includes robots, "Sitemap: https://blog.hotelbyte.com/llms.txt"
  end

  # ------------------------------------------------------------------
  # Multilingual jitter regression suite (added in WP07 refactor pass).
  # ------------------------------------------------------------------

  def test_layouts_use_page_lang_not_site_lang
    %w[default.html home.html post.html].each do |layout|
      body = read("_layouts/#{layout}")
      # The fix replaces `site.lang` (which defaults to en-US) with a chain
      # that prefers `page.lang`.
      assert_includes body, "page.lang | default: site.lang | default: 'en-US'",
                      "expected _layouts/#{layout} to source <html lang> from page.lang"
      refute_includes body, '{{ site.lang | default: "en-US" }}',
                       "_layouts/#{layout} still uses the broken site.lang default"
    end
  end

  def test_shared_site_chrome_include_exists_and_layouts_use_it
    chrome = read("_includes/site-chrome.html")
    assert_includes chrome, "<header class=\"site-header\""
    assert_includes chrome, "<footer class=\"site-footer\""
    assert_includes chrome, "language-switcher.html"

    %w[default.html home.html post.html].each do |layout|
      body = read("_layouts/#{layout}")
      assert_includes body, "site-chrome.html",
                      "_layouts/#{layout} should include site-chrome.html"
    end
  end

  def test_homepages_no_longer_use_settimeout_for_language_redirection
    %w[index.md en/index.md].each do |home|
      body = read(home)
      # The old code path used a 100ms setTimeout inside DOMContentLoaded to
      # bounce English browsers to /en/. That is exactly the flicker we are
      # eliminating; the new code path reads `localStorage` synchronously in
      # the document head.
      refute_match(/setTimeout\([^)]*,\s*\d+/, body,
                   "#{home} still uses setTimeout for language redirection")
      assert_includes body, "localStorage.getItem('hb-lang')",
                      "#{home} should consult hb-lang preference"
    end
  end

  def test_homepages_surface_language_suggestion_banner
    %w[index.md en/index.md].each do |home|
      body = read(home)
      assert_includes body, 'class="lang-suggest"', "#{home} should render .lang-suggest"
      assert_includes body, 'data-lang-action=', "#{home} should bind data-lang-action handlers"
    end
  end

  def test_language_switcher_consults_lang_pairs_table
    switcher = read("_includes/language-switcher.html")
    assert_includes switcher, "site.data.lang_pairs",
                     "language switcher should look up site.data.lang_pairs"
    assert_includes switcher, "no_english_counterpart",
                     "language switcher should honor the no_english_counterpart list"
  end

  def test_lang_pairs_table_is_in_sync_with_priority_routes
    pairs = YAML.safe_load(read("_data/lang_pairs.yml"))
    data = YAML.safe_load(read("_data/ai_geo.yml"))

    required_pairs = [
      ["/", "/en/"],
      ["/zh/whitepapers/", "/en/whitepapers/"],
      ["/zh/series/", "/en/series/"],
      ["/zh/archive/", "/en/archive/"],
      ["/zh/topics/hotel-api-integration/", "/en/topics/hotel-api-integration/"],
      ["/zh/topics/openapi-hotel-distribution/", "/en/topics/openapi-hotel-distribution/"]
    ]

    required_pairs.each do |zh, en|
      assert_includes data.fetch("priority_routes"), zh
      assert_includes data.fetch("priority_routes"), en
    end

    assert_includes pairs.fetch("home").fetch("zh"), "/"
    assert_includes pairs.fetch("home").fetch("en"), "/en/"

    assert_includes pairs.fetch("no_english_counterpart"), "/about/"
    assert_includes pairs.fetch("no_english_counterpart"), "/404.html"
    assert_includes pairs.fetch("no_english_counterpart"), "/en/404.html"
  end

  def test_ai_geo_head_emits_data_driven_hreflang_for_priority_pairs
    include_body = read("_includes/ai-geo-head.html")
    pairs = YAML.safe_load(read("_data/lang_pairs.yml"))

    # The data-driven loop should consult site.data.lang_pairs and emit
    # one hreflang="zh" + one hreflang="en" per priority entry.
    assert_includes include_body, "site.data.lang_pairs",
                     "ai-geo-head should drive hreflang from lang_pairs.yml"

    priority_keys = %w[home whitepaper_index series_index archive
                       topic_hotel_api_integration topic_openapi_hotel_distribution
                       notice_platform_rights]
    priority_keys.each do |key|
      assert pairs.key?(key), "lang_pairs.yml missing required entry: #{key}"
      assert pairs.fetch(key).key?("zh"), "lang_pairs entry #{key} missing zh"
      assert pairs.fetch(key).key?("en"), "lang_pairs entry #{key} missing en"
    end
  end

  def test_english_404_page_exists
    assert File.exist?(File.join(ROOT, "en/404.html")),
           "en/404.html must exist for the English-language 404 page"
    body = read("en/404.html")
    assert_includes body, "Page not found", "en/404.html should render English copy"
    assert_includes body, "404", "en/404.html should still display 404"
  end

  def test_404_pages_link_to_each_other
    zh_404 = read("404.html")
    en_404 = read("en/404.html")

    assert_includes zh_404, "/en/404.html", "zh 404 should link to /en/404.html"
    assert_includes en_404, "/404.html", "en 404 should link to /404.html"
  end

  def test_404_pages_drop_broken_domcontentloaded_language_detector
    zh_404 = read("404.html")
    refute_match(/addEventListener\(['"]DOMContentLoaded['"]/, zh_404,
                 "zh 404 should not run a late DOMContentLoaded redirect")
    refute_match(/en\/404\.html['"][^>]*style=['"]color:/, zh_404,
                 "zh 404 should not inject the broken dynamic Switch link")
  end

  def test_language_suggestion_styles_are_present
    css = read("assets/css/custom.css")
    assert_includes css, ".lang-suggest", "CSS should declare .lang-suggest"
    assert_includes css, ".lang-suggest__btn--primary",
                     "CSS should declare a primary CTA for the language banner"
  end
end