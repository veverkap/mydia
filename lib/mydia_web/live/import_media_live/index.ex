defmodule MydiaWeb.ImportMediaLive.Index do
  use MydiaWeb, :live_view

  alias Mydia.{Library, Metadata, Settings}
  alias Mydia.Library.{Scanner, MetadataMatcher}
  alias MydiaWeb.Live.Authorization

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Import Media")
     |> assign(:step, :select_path)
     |> assign(:scan_path, "")
     |> assign(:scanning, false)
     |> assign(:matching, false)
     |> assign(:importing, false)
     |> assign(:discovered_files, [])
     |> assign(:matched_files, [])
     |> assign(:selected_files, MapSet.new())
     |> assign(:scan_stats, %{total: 0, matched: 0, unmatched: 0, skipped: 0, orphaned: 0})
     |> assign(:library_paths, Settings.list_library_paths())
     |> assign(:metadata_config, Metadata.default_relay_config())
     |> assign(:import_progress, %{current: 0, total: 0, current_file: nil})
     |> assign(:import_results, %{success: 0, failed: 0, skipped: 0})
     |> assign(:detailed_results, [])}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  ## Event Handlers

  @impl true
  def handle_event("update_path", %{"value" => path}, socket) do
    {:noreply, assign(socket, :scan_path, path)}
  end

  def handle_event("select_library_path", %{"path_id" => path_id}, socket) do
    library_path = Enum.find(socket.assigns.library_paths, &(to_string(&1.id) == path_id))

    if library_path do
      {:noreply, assign(socket, :scan_path, library_path.path)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("start_scan", _params, socket) do
    with :ok <- Authorization.authorize_import_media(socket) do
      if String.trim(socket.assigns.scan_path) != "" do
        send(self(), {:perform_scan, socket.assigns.scan_path})

        {:noreply,
         socket
         |> assign(:scanning, true)
         |> assign(:step, :scanning)
         |> assign(:discovered_files, [])
         |> assign(:matched_files, [])}
      else
        {:noreply, put_flash(socket, :error, "Please enter a path to scan")}
      end
    else
      {:unauthorized, socket} -> {:noreply, socket}
    end
  end

  def handle_event("toggle_file_selection", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)
    selected_files = socket.assigns.selected_files

    selected_files =
      if MapSet.member?(selected_files, index) do
        MapSet.delete(selected_files, index)
      else
        MapSet.put(selected_files, index)
      end

    {:noreply, assign(socket, :selected_files, selected_files)}
  end

  def handle_event("select_all_files", _params, socket) do
    # Select only successfully matched files
    matched_indices =
      socket.assigns.matched_files
      |> Enum.with_index()
      |> Enum.filter(fn {file, _idx} -> file.match_result != nil end)
      |> Enum.map(fn {_file, idx} -> idx end)
      |> MapSet.new()

    {:noreply, assign(socket, :selected_files, matched_indices)}
  end

  def handle_event("deselect_all_files", _params, socket) do
    {:noreply, assign(socket, :selected_files, MapSet.new())}
  end

  def handle_event("start_import", _params, socket) do
    with :ok <- Authorization.authorize_import_media(socket) do
      if MapSet.size(socket.assigns.selected_files) > 0 do
        send(self(), :perform_import)

        {:noreply,
         socket
         |> assign(:importing, true)
         |> assign(:step, :importing)
         |> assign(
           :import_progress,
           %{current: 0, total: MapSet.size(socket.assigns.selected_files), current_file: nil}
         )}
      else
        {:noreply, put_flash(socket, :error, "Please select at least one file to import")}
      end
    else
      {:unauthorized, socket} -> {:noreply, socket}
    end
  end

  def handle_event("start_over", _params, socket) do
    {:noreply,
     socket
     |> assign(:step, :select_path)
     |> assign(:scan_path, "")
     |> assign(:discovered_files, [])
     |> assign(:matched_files, [])
     |> assign(:selected_files, MapSet.new())
     |> assign(:import_results, %{success: 0, failed: 0, skipped: 0})
     |> assign(:detailed_results, [])}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/media")}
  end

  def handle_event("retry_failed_item", %{"index" => index_str}, socket) do
    with :ok <- Authorization.authorize_import_media(socket) do
      index = String.to_integer(index_str)
      failed_item = Enum.at(socket.assigns.detailed_results, index)

      if failed_item && failed_item.status == :failed do
        # Find the original matched file from scan
        matched_file =
          Enum.find(socket.assigns.matched_files, fn mf ->
            mf.file.path == failed_item.file_path
          end)

        if matched_file do
          # Retry the import
          new_result = import_file_with_details(matched_file, socket.assigns.metadata_config)

          # Update the detailed results
          updated_results = List.replace_at(socket.assigns.detailed_results, index, new_result)

          # Recalculate counts
          success_count = Enum.count(updated_results, &(&1.status == :success))
          failed_count = Enum.count(updated_results, &(&1.status == :failed))
          skipped_count = Enum.count(updated_results, &(&1.status == :skipped))

          {:noreply,
           socket
           |> assign(:detailed_results, updated_results)
           |> assign(:import_results, %{
             success: success_count,
             failed: failed_count,
             skipped: skipped_count
           })
           |> put_flash(:info, "Retried import for #{failed_item.file_name}")}
        else
          {:noreply, put_flash(socket, :error, "Could not find original file data")}
        end
      else
        {:noreply, put_flash(socket, :error, "Invalid retry request")}
      end
    else
      {:unauthorized, socket} -> {:noreply, socket}
    end
  end

  def handle_event("retry_all_failed", _params, socket) do
    with :ok <- Authorization.authorize_import_media(socket) do
      # Get all failed items with their indices
      failed_items_with_indices =
        socket.assigns.detailed_results
        |> Enum.with_index()
        |> Enum.filter(fn {result, _idx} -> result.status == :failed end)

      if failed_items_with_indices == [] do
        {:noreply, put_flash(socket, :info, "No failed items to retry")}
      else
        # Retry each failed item
        updated_results =
          Enum.reduce(failed_items_with_indices, socket.assigns.detailed_results, fn {failed_item,
                                                                                      index},
                                                                                     acc_results ->
            # Find the original matched file
            matched_file =
              Enum.find(socket.assigns.matched_files, fn mf ->
                mf.file.path == failed_item.file_path
              end)

            if matched_file do
              new_result = import_file_with_details(matched_file, socket.assigns.metadata_config)
              List.replace_at(acc_results, index, new_result)
            else
              acc_results
            end
          end)

        # Recalculate counts
        success_count = Enum.count(updated_results, &(&1.status == :success))
        failed_count = Enum.count(updated_results, &(&1.status == :failed))
        skipped_count = Enum.count(updated_results, &(&1.status == :skipped))

        {:noreply,
         socket
         |> assign(:detailed_results, updated_results)
         |> assign(:import_results, %{
           success: success_count,
           failed: failed_count,
           skipped: skipped_count
         })
         |> put_flash(:info, "Retried #{length(failed_items_with_indices)} failed items")}
      end
    else
      {:unauthorized, socket} -> {:noreply, socket}
    end
  end

  def handle_event("export_results", _params, socket) do
    # Generate JSON export of detailed results
    export_data = %{
      timestamp: DateTime.utc_now(),
      summary: socket.assigns.import_results,
      results: socket.assigns.detailed_results
    }

    json_data = Jason.encode!(export_data, pretty: true)

    {:noreply,
     socket
     |> push_event("download_export", %{
       filename: "import_results_#{DateTime.utc_now() |> DateTime.to_unix()}.json",
       content: json_data,
       mime_type: "application/json"
     })}
  end

  ## Async Handlers

  @impl true
  def handle_info({:perform_scan, path}, socket) do
    case Scanner.scan(path) do
      {:ok, scan_result} ->
        # Get existing files from database
        # Only skip files that have valid parent associations (not orphaned)
        existing_files = Library.list_media_files()

        existing_valid_paths =
          existing_files
          |> Enum.reject(&Library.orphaned_media_file?/1)
          |> MapSet.new(& &1.path)

        # Build map of orphaned files for re-matching
        orphaned_files_map =
          existing_files
          |> Enum.filter(&Library.orphaned_media_file?/1)
          |> Map.new(&{&1.path, &1})

        # Filter out files that already have valid associations
        # Include orphaned files for re-matching
        new_files =
          Enum.reject(scan_result.files, fn file ->
            MapSet.member?(existing_valid_paths, file.path)
          end)

        # Track which files are orphaned (for re-matching)
        files_to_match =
          Enum.map(new_files, fn file ->
            orphaned_file = Map.get(orphaned_files_map, file.path)

            Map.put(file, :orphaned_media_file_id, orphaned_file && orphaned_file.id)
          end)

        skipped_count = length(scan_result.files) - length(new_files)
        orphaned_count = map_size(orphaned_files_map)

        # Start matching files
        send(self(), {:match_files, files_to_match})

        {:noreply,
         socket
         |> assign(:scanning, false)
         |> assign(:matching, true)
         |> assign(:discovered_files, scan_result.files)
         |> assign(
           :scan_stats,
           %{
             total: length(files_to_match),
             matched: 0,
             unmatched: 0,
             skipped: skipped_count,
             orphaned: orphaned_count
           }
         )}

      {:error, reason} ->
        {:noreply,
         socket
         |> assign(:scanning, false)
         |> assign(:step, :select_path)
         |> put_flash(:error, "Scan failed: #{format_error(reason)}")}
    end
  end

  def handle_info({:match_files, files}, socket) do
    # Match files with TMDB in batches for better UX
    matched_files =
      Enum.map(files, fn file ->
        match_result =
          case MetadataMatcher.match_file(file.path, config: socket.assigns.metadata_config) do
            {:ok, match} -> match
            {:error, _reason} -> nil
          end

        %{
          file: file,
          match_result: match_result,
          import_status: :pending
        }
      end)

    # Calculate stats
    matched_count = Enum.count(matched_files, &(&1.match_result != nil))
    unmatched_count = length(matched_files) - matched_count

    # Auto-select files with high confidence matches
    auto_selected =
      matched_files
      |> Enum.with_index()
      |> Enum.filter(fn {file, _idx} ->
        file.match_result != nil && file.match_result.match_confidence >= 0.8
      end)
      |> Enum.map(fn {_file, idx} -> idx end)
      |> MapSet.new()

    {:noreply,
     socket
     |> assign(:matching, false)
     |> assign(:step, :review)
     |> assign(:matched_files, matched_files)
     |> assign(:selected_files, auto_selected)
     |> assign(:scan_stats, %{
       total: length(files),
       matched: matched_count,
       unmatched: unmatched_count,
       skipped: socket.assigns.scan_stats.skipped
     })}
  end

  def handle_info(:perform_import, socket) do
    selected_indices = MapSet.to_list(socket.assigns.selected_files)
    selected_files = Enum.map(selected_indices, &Enum.at(socket.assigns.matched_files, &1))

    # Import each file and collect detailed results
    detailed_results =
      Enum.with_index(selected_files)
      |> Enum.map(fn {matched_file, idx} ->
        # Update progress with current file
        file_name = Path.basename(matched_file.file.path)
        send(self(), {:update_import_progress, idx + 1, file_name})

        import_file_with_details(matched_file, socket.assigns.metadata_config)
      end)

    success_count = Enum.count(detailed_results, &(&1.status == :success))
    failed_count = Enum.count(detailed_results, &(&1.status == :failed))
    skipped_count = Enum.count(detailed_results, &(&1.status == :skipped))

    {:noreply,
     socket
     |> assign(:importing, false)
     |> assign(:step, :complete)
     |> assign(:import_results, %{
       success: success_count,
       failed: failed_count,
       skipped: skipped_count
     })
     |> assign(:detailed_results, detailed_results)}
  end

  def handle_info({:update_import_progress, current, current_file}, socket) do
    {:noreply,
     assign(socket, :import_progress, %{
       socket.assigns.import_progress
       | current: current,
         current_file: current_file
     })}
  end

  ## Private Helpers

  defp import_file_with_details(%{match_result: nil, file: file}, _config) do
    %{
      file_path: file.path,
      file_name: Path.basename(file.path),
      status: :failed,
      media_item_title: nil,
      error_message: "No metadata match found for this file",
      action_taken: nil,
      metadata: %{size: file.size}
    }
  end

  defp import_file_with_details(%{file: file, match_result: match_result}, config) do
    # Check if this file is orphaned and needs re-matching
    media_file_result =
      if file[:orphaned_media_file_id] do
        # Use existing orphaned media file - don't update it yet
        # The enricher will handle associating it with the media item
        try do
          media_file = Library.get_media_file!(file.orphaned_media_file_id)
          {:ok, media_file}
        rescue
          _ -> {:error, :not_found}
        end
      else
        # Create new media file record
        Library.create_scanned_media_file(%{
          path: file.path,
          size: file.size,
          verified_at: DateTime.utc_now()
        })
      end

    case media_file_result do
      {:ok, media_file} ->
        # Enrich with metadata
        case Library.MetadataEnricher.enrich(match_result,
               config: config,
               media_file_id: media_file.id
             ) do
          {:ok, media_item} ->
            %{
              file_path: file.path,
              file_name: Path.basename(file.path),
              status: :success,
              media_item_title: match_result.title,
              error_message: nil,
              action_taken: build_success_message(match_result, file[:orphaned_media_file_id]),
              metadata: %{
                size: file.size,
                media_item_id: media_item.id,
                year: match_result.year,
                type: match_result.parsed_info.type
              }
            }

          {:error, reason} ->
            %{
              file_path: file.path,
              file_name: Path.basename(file.path),
              status: :failed,
              media_item_title: match_result.title,
              error_message: "Failed to enrich metadata: #{format_error(reason)}",
              action_taken: nil,
              metadata: %{size: file.size}
            }
        end

      {:error, changeset} ->
        error_msg =
          case changeset do
            %Ecto.Changeset{errors: errors} ->
              errors
              |> Enum.map(fn {field, {msg, _}} -> "#{field} #{msg}" end)
              |> Enum.join(", ")

            other ->
              format_error(other)
          end

        %{
          file_path: file.path,
          file_name: Path.basename(file.path),
          status: :failed,
          media_item_title: match_result.title,
          error_message: "Database error: #{error_msg}",
          action_taken: nil,
          metadata: %{size: file.size}
        }
    end
  rescue
    error ->
      %{
        file_path: file.path,
        file_name: Path.basename(file.path),
        status: :failed,
        media_item_title: match_result && match_result.title,
        error_message: "Unexpected error: #{Exception.message(error)}",
        action_taken: nil,
        metadata: %{size: file.size}
      }
  end

  defp build_success_message(match_result, is_orphaned) do
    media_type =
      case match_result.parsed_info.type do
        :tv_show ->
          if match_result.parsed_info.season do
            "TV Show S#{String.pad_leading("#{match_result.parsed_info.season}", 2, "0")}"
          else
            "TV Show"
          end

        _ ->
          "Movie"
      end

    action =
      if is_orphaned do
        "Re-matched orphaned file as #{media_type}"
      else
        "Created #{media_type}"
      end

    "#{action}: '#{match_result.title}'"
  end

  defp import_file(%{match_result: nil}, _config), do: :error

  defp import_file(%{file: file, match_result: match_result}, config) do
    # Check if this file is orphaned and needs re-matching
    media_file_result =
      if file[:orphaned_media_file_id] do
        # Use existing orphaned media file - don't update it yet
        # The enricher will handle associating it with the media item
        try do
          media_file = Library.get_media_file!(file.orphaned_media_file_id)
          {:ok, media_file}
        rescue
          _ -> {:error, :not_found}
        end
      else
        # Create new media file record
        Library.create_scanned_media_file(%{
          path: file.path,
          size: file.size,
          verified_at: DateTime.utc_now()
        })
      end

    case media_file_result do
      {:ok, media_file} ->
        # Enrich with metadata
        case Library.MetadataEnricher.enrich(match_result,
               config: config,
               media_file_id: media_file.id
             ) do
          {:ok, _media_item} -> :ok
          {:error, _reason} -> :error
        end

      {:error, _changeset} ->
        :error
    end
  rescue
    _ -> :error
  end

  defp format_error(:not_found), do: "Directory not found"
  defp format_error(:not_directory), do: "Path is not a directory"
  defp format_error(:permission_denied), do: "Permission denied"
  defp format_error(reason), do: inspect(reason)

  defp format_file_size(size) when size < 1024, do: "#{size} B"
  defp format_file_size(size) when size < 1_048_576, do: "#{Float.round(size / 1024, 1)} KB"

  defp format_file_size(size) when size < 1_073_741_824,
    do: "#{Float.round(size / 1_048_576, 1)} MB"

  defp format_file_size(size), do: "#{Float.round(size / 1_073_741_824, 1)} GB"

  defp confidence_badge_class(confidence) when confidence >= 0.8, do: "badge-success"
  defp confidence_badge_class(confidence) when confidence >= 0.5, do: "badge-warning"
  defp confidence_badge_class(_), do: "badge-error"

  defp confidence_label(confidence) when confidence >= 0.8, do: "High"
  defp confidence_label(confidence) when confidence >= 0.5, do: "Medium"
  defp confidence_label(_), do: "Low"
end
