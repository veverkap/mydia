defmodule Mydia.Indexers.CardigannResultParserTest do
  use ExUnit.Case, async: true

  alias Mydia.Indexers.CardigannResultParser
  alias Mydia.Indexers.CardigannDefinition.Parsed
  alias Mydia.Indexers.SearchResult

  describe "parse_results/3 with HTML" do
    test "parses simple HTML table results" do
      definition = %Parsed{
        id: "test",
        name: "Test Indexer",
        search: %{
          rows: %{
            selector: "table.results tbody tr"
          },
          fields: %{
            "title" => %{selector: "td.title a"},
            "download" => %{selector: "td.download a", attribute: "href"},
            "size" => %{selector: "td.size"},
            "seeders" => %{selector: "td.seeders"},
            "leechers" => %{selector: "td.leechers"}
          }
        }
      }

      html_body = """
      <html>
        <body>
          <table class="results">
            <tbody>
              <tr>
                <td class="title"><a>Ubuntu 22.04 LTS 1080p</a></td>
                <td class="size">4.5 GB</td>
                <td class="seeders">100</td>
                <td class="leechers">50</td>
                <td class="download"><a href="magnet:?xt=urn:btih:abc123">Download</a></td>
              </tr>
              <tr>
                <td class="title"><a>Debian 12 ISO</a></td>
                <td class="size">650 MB</td>
                <td class="seeders">200</td>
                <td class="leechers">25</td>
                <td class="download"><a href="magnet:?xt=urn:btih:def456">Download</a></td>
              </tr>
            </tbody>
          </table>
        </body>
      </html>
      """

      response = %{status: 200, body: html_body}

      assert {:ok, results} = CardigannResultParser.parse_results(definition, response, "Test")
      assert length(results) == 2

      [result1, result2] = results

      assert %SearchResult{} = result1
      assert result1.title == "Ubuntu 22.04 LTS 1080p"
      assert result1.size == 4_831_838_208
      assert result1.seeders == 100
      assert result1.leechers == 50
      assert result1.download_url == "magnet:?xt=urn:btih:abc123"
      assert result1.indexer == "Test"

      assert result2.title == "Debian 12 ISO"
      assert result2.size == 681_574_400
      assert result2.seeders == 200
      assert result2.leechers == 25
    end

    test "skips header rows with 'after' configuration" do
      definition = %Parsed{
        id: "test",
        name: "Test Indexer",
        search: %{
          rows: %{
            selector: "table tr",
            after: 1
          },
          fields: %{
            "title" => %{selector: "td:nth-child(1)"},
            "download" => %{selector: "td:nth-child(2)", attribute: "data-url"},
            "size" => %{selector: "td:nth-child(3)"},
            "seeders" => %{selector: "td:nth-child(4)"},
            "leechers" => %{selector: "td:nth-child(5)"}
          }
        }
      }

      html_body = """
      <table>
        <tr>
          <th>Title</th><th>Download</th><th>Size</th><th>Seeders</th><th>Leechers</th>
        </tr>
        <tr>
          <td>Test Release</td>
          <td data-url="magnet:?xt=urn:btih:test">Link</td>
          <td>1.5 GB</td>
          <td>10</td>
          <td>5</td>
        </tr>
      </table>
      """

      response = %{status: 200, body: html_body}

      assert {:ok, results} = CardigannResultParser.parse_results(definition, response, "Test")
      assert length(results) == 1
      assert hd(results).title == "Test Release"
    end

    test "filters out rows missing required fields" do
      definition = %Parsed{
        id: "test",
        name: "Test Indexer",
        search: %{
          rows: %{selector: "div.result"},
          fields: %{
            "title" => %{selector: "div.title"},
            "download" => %{selector: "a.download", attribute: "href"},
            "size" => %{selector: "div.size"},
            "seeders" => %{selector: "div.seeders"},
            "leechers" => %{selector: "div.leechers"}
          }
        }
      }

      html_body = """
      <div class="result">
        <div class="title">Complete Release</div>
        <div class="size">1 GB</div>
        <div class="seeders">50</div>
        <div class="leechers">10</div>
        <a class="download" href="magnet:?xt=urn:btih:complete">Download</a>
      </div>
      <div class="result">
        <div class="title">Missing Download Link</div>
        <div class="size">2 GB</div>
        <div class="seeders">30</div>
        <div class="leechers">5</div>
      </div>
      <div class="result">
        <div class="size">3 GB</div>
        <div class="seeders">20</div>
        <div class="leechers">3</div>
        <a class="download" href="magnet:?xt=urn:btih:notitle">Download</a>
      </div>
      """

      response = %{status: 200, body: html_body}

      assert {:ok, results} = CardigannResultParser.parse_results(definition, response, "Test")
      assert length(results) == 1
      assert hd(results).title == "Complete Release"
    end
  end

  describe "apply_filters/2" do
    test "applies replace filter" do
      filters = [%{name: "replace", args: [" GB", ""]}]
      assert {:ok, "1.5"} = CardigannResultParser.apply_filters("1.5 GB", filters)
    end

    test "applies replace filter with string keys" do
      filters = [%{"name" => "replace", "args" => ["[", ""]}]
      assert {:ok, "test]"} = CardigannResultParser.apply_filters("[test]", filters)
    end

    test "applies re_replace filter" do
      filters = [%{name: "re_replace", args: ["\\[.*?\\]", ""]}]
      assert {:ok, " Test"} = CardigannResultParser.apply_filters("[Tag] Test", filters)
    end

    test "applies re_replace filter with string keys" do
      filters = [%{"name" => "re_replace", "args" => ["\\s+", "_"]}]
      assert {:ok, "hello_world"} = CardigannResultParser.apply_filters("hello  world", filters)
    end

    test "applies append filter" do
      filters = [%{name: "append", args: [".torrent"]}]
      assert {:ok, "file.torrent"} = CardigannResultParser.apply_filters("file", filters)
    end

    test "applies prepend filter" do
      filters = [%{name: "prepend", args: ["https://"]}]

      assert {:ok, "https://example.com"} =
               CardigannResultParser.apply_filters("example.com", filters)
    end

    test "applies trim filter" do
      filters = [%{name: "trim"}]
      assert {:ok, "test"} = CardigannResultParser.apply_filters("  test  ", filters)
    end

    test "applies multiple filters in sequence" do
      filters = [
        %{name: "trim"},
        %{name: "replace", args: [" GB", ""]},
        %{name: "append", args: [" bytes"]}
      ]

      assert {:ok, "1.5 bytes"} = CardigannResultParser.apply_filters("  1.5 GB  ", filters)
    end

    test "ignores unknown filters" do
      filters = [%{name: "unknown_filter", args: ["test"]}]
      assert {:ok, "value"} = CardigannResultParser.apply_filters("value", filters)
    end

    test "returns original value with empty filter list" do
      assert {:ok, "test"} = CardigannResultParser.apply_filters("test", [])
    end
  end

  describe "parse_size/1" do
    test "parses gigabytes" do
      assert CardigannResultParser.parse_size("1.5 GB") == 1_610_612_736
      assert CardigannResultParser.parse_size("2 GiB") == 2_147_483_648
      assert CardigannResultParser.parse_size("0.5GB") == 536_870_912
    end

    test "parses megabytes" do
      assert CardigannResultParser.parse_size("500 MB") == 524_288_000
      assert CardigannResultParser.parse_size("1024 MiB") == 1_073_741_824
      assert CardigannResultParser.parse_size("1.5MB") == 1_572_864
    end

    test "parses kilobytes" do
      assert CardigannResultParser.parse_size("1024 KB") == 1_048_576
      assert CardigannResultParser.parse_size("500 KiB") == 512_000
    end

    test "parses terabytes" do
      assert CardigannResultParser.parse_size("1.5 TB") == 1_649_267_441_664
    end

    test "parses plain bytes" do
      assert CardigannResultParser.parse_size("1024") == 1024
      assert CardigannResultParser.parse_size("500") == 500
    end

    test "handles nil and empty strings" do
      assert CardigannResultParser.parse_size(nil) == 0
      assert CardigannResultParser.parse_size("") == 0
    end

    test "handles malformed size strings" do
      assert CardigannResultParser.parse_size("invalid") == 0
      assert CardigannResultParser.parse_size("N/A") == 0
    end
  end

  describe "parse_date/1" do
    test "parses ISO 8601 datetime" do
      result = CardigannResultParser.parse_date("2024-01-15T12:30:00Z")
      assert %DateTime{} = result
      assert result.year == 2024
      assert result.month == 1
      assert result.day == 15
    end

    test "handles nil and empty strings" do
      assert CardigannResultParser.parse_date(nil) == nil
      assert CardigannResultParser.parse_date("") == nil
    end

    test "handles invalid date strings gracefully" do
      assert CardigannResultParser.parse_date("invalid") == nil
      assert CardigannResultParser.parse_date("not a date") == nil
    end
  end

  describe "parse_results/3 with JSON" do
    test "parses simple JSON results" do
      definition = %Parsed{
        id: "test",
        name: "Test JSON Indexer",
        search: %{
          rows: %{selector: "$.results"},
          fields: %{
            "title" => %{selector: "name"},
            "download" => %{selector: "magnet"},
            "size" => %{selector: "bytes"},
            "seeders" => %{selector: "seeds"},
            "leechers" => %{selector: "peers"}
          }
        }
      }

      json_body = """
      {
        "results": [
          {
            "name": "Ubuntu 22.04",
            "magnet": "magnet:?xt=urn:btih:abc123",
            "bytes": "4500000000",
            "seeds": "100",
            "peers": "50"
          },
          {
            "name": "Debian 12",
            "magnet": "magnet:?xt=urn:btih:def456",
            "bytes": "650000000",
            "seeds": "200",
            "peers": "25"
          }
        ]
      }
      """

      response = %{status: 200, body: json_body}

      assert {:ok, results} =
               CardigannResultParser.parse_results(definition, response, "TestJSON")

      assert length(results) == 2

      [result1, result2] = results

      assert result1.title == "Ubuntu 22.04"
      assert result1.download_url == "magnet:?xt=urn:btih:abc123"
      assert result1.size == 4_500_000_000
      assert result1.seeders == 100
      assert result1.leechers == 50
      assert result1.indexer == "TestJSON"

      assert result2.title == "Debian 12"
      assert result2.seeders == 200
    end

    test "handles invalid JSON gracefully" do
      definition = %Parsed{
        id: "test",
        name: "Test Indexer",
        search: %{
          rows: %{selector: "$.results"},
          fields: %{
            "title" => %{selector: "name"},
            "download" => %{selector: "link"}
          }
        }
      }

      response = %{status: 200, body: "not valid json {"}

      # Invalid JSON that looks like JSON will be treated as HTML
      # and return empty results since no HTML elements match
      assert {:ok, []} = CardigannResultParser.parse_results(definition, response, "Test")
    end
  end

  describe "HTML field extraction" do
    test "extracts text content from elements" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        search: %{
          rows: %{selector: "div.item"},
          fields: %{
            "title" => %{selector: "h1"},
            "download" => %{selector: "a", attribute: "href"},
            "size" => %{selector: "span.size"},
            "seeders" => %{selector: "span.seeds"},
            "leechers" => %{selector: "span.peers"}
          }
        }
      }

      html_body = """
      <div class="item">
        <h1>Test  Title  </h1>
        <span class="size">1 GB</span>
        <span class="seeds">10</span>
        <span class="peers">5</span>
        <a href="magnet:?xt=test">Download</a>
      </div>
      """

      response = %{status: 200, body: html_body}

      assert {:ok, [result]} = CardigannResultParser.parse_results(definition, response, "Test")
      assert result.title == "Test  Title"
    end

    test "extracts attributes from elements" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        search: %{
          rows: %{selector: "div.item"},
          fields: %{
            "title" => %{selector: "a", attribute: "title"},
            "download" => %{selector: "a", attribute: "href"},
            "category" => %{selector: "div", attribute: "data-category"},
            "size" => %{selector: "span"},
            "seeders" => %{selector: "span"},
            "leechers" => %{selector: "span"}
          }
        }
      }

      html_body = """
      <div class="item" data-category="movies">
        <a href="magnet:?xt=test" title="Test Movie 1080p">Download</a>
        <span>1 GB</span>
      </div>
      """

      response = %{status: 200, body: html_body}

      assert {:ok, [result]} = CardigannResultParser.parse_results(definition, response, "Test")
      assert result.title == "Test Movie 1080p"
      assert result.download_url == "magnet:?xt=test"
      assert result.category == 0
    end

    test "applies filters to extracted fields" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        search: %{
          rows: %{selector: "div.item"},
          fields: %{
            "title" => %{
              selector: "h1",
              filters: [
                %{name: "re_replace", args: ["\\[.*?\\]", ""]},
                %{name: "trim"}
              ]
            },
            "download" => %{selector: "a", attribute: "href"},
            "size" => %{
              selector: "span.size",
              filters: [%{name: "replace", args: [" ", ""]}]
            },
            "seeders" => %{selector: "span.seeds"},
            "leechers" => %{selector: "span.peers"}
          }
        }
      }

      html_body = """
      <div class="item">
        <h1>  [Tag] Test Movie 1080p  </h1>
        <span class="size">1.5 GB</span>
        <span class="seeds">10</span>
        <span class="peers">5</span>
        <a href="magnet:?xt=test">Download</a>
      </div>
      """

      response = %{status: 200, body: html_body}

      assert {:ok, [result]} = CardigannResultParser.parse_results(definition, response, "Test")
      assert result.title == "Test Movie 1080p"
      assert result.size == 1_610_612_736
    end
  end

  describe "quality parsing integration" do
    test "parses quality from titles" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        search: %{
          rows: %{selector: "div.item"},
          fields: %{
            "title" => %{selector: "div.title"},
            "download" => %{selector: "a", attribute: "href"},
            "size" => %{selector: "div.size"},
            "seeders" => %{selector: "div.seeds"},
            "leechers" => %{selector: "div.peers"}
          }
        }
      }

      html_body = """
      <div class="item">
        <div class="title">Test.Movie.2024.1080p.BluRay.x264-GROUP</div>
        <div class="size">5 GB</div>
        <div class="seeds">100</div>
        <div class="peers">50</div>
        <a href="magnet:?xt=test">Download</a>
      </div>
      """

      response = %{status: 200, body: html_body}

      assert {:ok, [result]} = CardigannResultParser.parse_results(definition, response, "Test")
      assert result.quality != nil
      assert result.quality.resolution == "1080p"
      assert result.quality.source == "BluRay"
      assert result.quality.codec == "x264"
    end
  end

  describe "edge cases" do
    test "handles empty HTML response" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        search: %{
          rows: %{selector: "div.item"},
          fields: %{
            "title" => %{selector: "div.title"},
            "download" => %{selector: "a", attribute: "href"}
          }
        }
      }

      response = %{status: 200, body: "<html><body></body></html>"}

      assert {:ok, []} = CardigannResultParser.parse_results(definition, response, "Test")
    end

    test "handles malformed HTML gracefully" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        search: %{
          rows: %{selector: "div.item"},
          fields: %{
            "title" => %{selector: "div.title"},
            "download" => %{selector: "a", attribute: "href"},
            "size" => %{selector: "div.size"},
            "seeders" => %{selector: "div.seeds"},
            "leechers" => %{selector: "div.peers"}
          }
        }
      }

      html_body = """
      <div class="item">
        <div class="title">Test</div>
        <div class="size">1 GB</div>
        <div class="seeds">10</div>
        <div class="peers">5</div>
        <a href="magnet:?xt=test">Download
      </div>
      """

      response = %{status: 200, body: html_body}

      # Should still parse successfully despite unclosed tag
      assert {:ok, [result]} = CardigannResultParser.parse_results(definition, response, "Test")
      assert result.title == "Test"
    end

    test "handles missing size/seeders/leechers gracefully" do
      definition = %Parsed{
        id: "test",
        name: "Test",
        search: %{
          rows: %{selector: "div.item"},
          fields: %{
            "title" => %{selector: "div.title"},
            "download" => %{selector: "a", attribute: "href"},
            "size" => %{selector: "div.size"},
            "seeders" => %{selector: "div.seeds"},
            "leechers" => %{selector: "div.peers"}
          }
        }
      }

      html_body = """
      <div class="item">
        <div class="title">Test Release</div>
        <a href="magnet:?xt=test">Download</a>
      </div>
      """

      response = %{status: 200, body: html_body}

      assert {:ok, [result]} = CardigannResultParser.parse_results(definition, response, "Test")
      assert result.title == "Test Release"
      assert result.size == 0
      assert result.seeders == 0
      assert result.leechers == 0
    end
  end
end
