defmodule ChatWeb.PageLive do
  # any controller need a same html name
  use ChatWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, query: "", results: %{})}
  end

  @impl true
  def handle_event("create-user",  %{"create" => %{"user" => user}}, socket) do
    slug = "/" <> user
    Logger.info(slug)
    # {:noreply, socket}
    {:noreply, push_redirect(socket, to:  slug)}
  end
end
