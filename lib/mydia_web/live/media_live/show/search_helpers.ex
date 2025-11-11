defmodule MydiaWeb.MediaLive.Show.SearchHelpers do
  @moduledoc """
  Search-related helper functions for the MediaLive.Show page.
  Handles manual search, filtering, sorting, and result processing.
  """

  alias Mydia.Indexers
  alias Mydia.Indexers.SearchResult
  alias Mydia.Indexers.QualityParser

  def generate_result_id(%SearchResult{} = result) do
    # Generate a unique ID based on the download URL and indexer
    # Use :erlang.phash2 to create a stable integer ID from the URL
    hash = :erlang.phash2({result.download_url, result.indexer})
    "search-result-#{hash}"
  end

  def perform_search(query, min_seeders) do
    opts = [
      min_seeders: min_seeders,
      deduplicate: true
    ]

    Indexers.search_all(query, opts)
  end

  def apply_search_filters(socket) do
    # Re-filter the current results without re-searching
    results = socket.assigns.search_results |> Enum.map(fn {_id, result} -> result end)
    filtered_results = filter_search_results(results, socket.assigns)
    sorted_results = sort_search_results(filtered_results, socket.assigns.sort_by)

    socket
    |> Phoenix.Component.assign(:results_empty?, sorted_results == [])
    |> Phoenix.LiveView.stream(:search_results, sorted_results, reset: true)
  end

  def apply_search_sort(socket) do
    # Re-sort the current results
    results = socket.assigns.search_results |> Enum.map(fn {_id, result} -> result end)
    sorted_results = sort_search_results(results, socket.assigns.sort_by)

    socket
    |> Phoenix.LiveView.stream(:search_results, sorted_results, reset: true)
  end

  def filter_search_results(results, assigns) do
    results
    |> filter_by_seeders(assigns.min_seeders)
    |> filter_by_quality(assigns.quality_filter)
  end

  defp filter_by_seeders(results, min_seeders) when min_seeders > 0 do
    Enum.filter(results, fn result -> result.seeders >= min_seeders end)
  end

  defp filter_by_seeders(results, _), do: results

  defp filter_by_quality(results, nil), do: results

  defp filter_by_quality(results, quality_filter) do
    Enum.filter(results, fn result ->
      case result.quality do
        %{resolution: resolution} when not is_nil(resolution) ->
          # Normalize 2160p to 4k and vice versa
          normalized_resolution = normalize_resolution(resolution)
          normalized_filter = normalize_resolution(quality_filter)
          normalized_resolution == normalized_filter

        _ ->
          false
      end
    end)
  end

  defp normalize_resolution("2160p"), do: "4k"
  defp normalize_resolution("4k"), do: "4k"
  defp normalize_resolution(res), do: String.downcase(res)

  def sort_search_results(results, :quality) do
    # Sort by quality score (already done by search_all), then by seeders
    results
    |> Enum.sort_by(fn result -> {quality_score(result), result.seeders} end, :desc)
  end

  def sort_search_results(results, :seeders) do
    Enum.sort_by(results, & &1.seeders, :desc)
  end

  def sort_search_results(results, :size) do
    Enum.sort_by(results, & &1.size, :desc)
  end

  def sort_search_results(results, :date) do
    Enum.sort_by(
      results,
      fn result ->
        case result.published_at do
          nil -> DateTime.from_unix!(0)
          dt -> dt
        end
      end,
      {:desc, DateTime}
    )
  end

  defp quality_score(%SearchResult{quality: nil}), do: 0

  defp quality_score(%SearchResult{quality: quality}) do
    QualityParser.quality_score(quality)
  end

  # Helper functions for the search results template

  def get_search_quality_badge(%SearchResult{} = result) do
    SearchResult.quality_description(result)
  end

  def search_health_score(%SearchResult{} = result) do
    SearchResult.health_score(result)
  end
end
