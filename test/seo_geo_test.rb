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
end
