defmodule MydiaWeb.AdminStatusLiveTest do
  use MydiaWeb.ConnCase

  import Phoenix.LiveViewTest
  import MydiaWeb.AuthHelpers
  import Mydia.AccountsFixtures

  describe "Index - Authentication" do
    test "requires authentication", %{conn: conn} do
      {:error, {:redirect, %{to: path}}} = live(conn, ~p"/admin/status")
      # Should redirect to login
      assert path =~ "/auth"
    end

    test "requires admin role", %{conn: conn} do
      # Create and log in a regular user (non-admin)
      user = user_fixture(%{role: "user"})
      conn = log_in_user(conn, user)

      # Regular user should be redirected when trying to access admin status
      {:error, {:redirect, %{to: path, flash: flash}}} = live(conn, ~p"/admin/status")

      # Should redirect to home page
      assert path == "/"
      # Should have an error flash message
      assert flash["error"] =~ "permission"
    end

    test "allows admin access", %{conn: conn} do
      admin = admin_user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, _view, html} = live(conn, ~p"/admin/status")
      assert html =~ "System Status"
    end
  end

  describe "Index - Content" do
    setup %{conn: conn} do
      admin = admin_user_fixture()
      conn = log_in_user(conn, admin)

      {:ok, view, _html} = live(conn, ~p"/admin/status")
      %{conn: conn, view: view}
    end

    test "displays system information", %{view: view} do
      assert has_element?(view, "h2", "System Information")
      assert has_element?(view, ".stat-title", "App Version")
      assert has_element?(view, ".stat-title", "Elixir Version")
      assert has_element?(view, ".stat-title", "OTP Version")
      assert has_element?(view, ".stat-title", "Uptime")
    end

    test "displays database information", %{view: view} do
      assert has_element?(view, "h2", "Database")
    end

    test "displays database adapter-specific information", %{view: view} do
      html = render(view)

      # Should always show Size:
      assert html =~ "Size:"

      if Mydia.DB.postgres?() do
        # PostgreSQL mode
        assert html =~ "PostgreSQL"
        assert html =~ "Host:"
        assert html =~ "Database:"
        refute html =~ "Exists:"
      else
        # SQLite mode
        assert html =~ "SQLite"
        assert html =~ "Location:"
        assert html =~ "Exists:"
      end
    end

    test "displays database adapter in settings", %{view: view} do
      html = render(view)
      # Should show the database adapter in the Database settings section
      assert html =~ "database.adapter"

      if Mydia.DB.postgres?() do
        assert html =~ "database.hostname"
        assert html =~ "database.name"
        refute html =~ "database.path"
      else
        assert html =~ "database.path"
        refute html =~ "database.hostname"
      end
    end
  end
end
