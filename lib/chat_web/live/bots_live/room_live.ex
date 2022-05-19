defmodule ChatWeb.RoomLive do
  # any controller need a same html name
  use ChatWeb, :live_view
  require Logger

  @impl true
  # def mount(%{"id" => user}, _session, socket) do #pattern matching
  def mount(params, _session, socket) do
  
    %{"id" => user} = params
    topic = "tlo"
    if connected?(socket) do 
      ChatWeb.Endpoint.subscribe(topic)
    end
    {:ok, assign(socket, user: user, 
      topic: topic, 
      message: "",
      messages: [], 
      users: [],
      temporary_assigns: [messages: [], users: []] 
    )}

    # {:ok, assign(socket, user: user, topic: topic, messages: [],  ), temporary_assigns: [messages: []]}
  end

  @impl true
  def handle_params(_params, _uri, socket)  do
    ChatWeb.Presence.track(self(), socket.assigns.topic, socket.assigns.user, %{})
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit-message", %{"chat" => %{"message" => message}}, socket) do
  # def handle_event("submit-message", params, socket) do
    Logger.info(message: message)
    ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", %{uuid: UUID.uuid4() , user: socket.assigns.user, message: message})
    {:noreply, assign(socket, message: "")}
  end


  @impl true
  def handle_event("input-message", %{"chat" => %{"message" => message}}, socket) do
  # def handle_event("submit-message", params, socket) do
    Logger.info(input: message)
    {:noreply, assign(socket, message: message)}
  end

  @impl true
  def handle_info(%{ event: "new-message", payload: message }, socket) do
    Logger.info(payload: message)
    {:noreply, assign(socket, messages: [message])}
    # {:noreply, update(socket, :messages , fn x -> message ++ x  end )}
  end

  @impl true
  def handle_info(%{ event: "presence_diff", payload: %{joins: joins, leaves: leaves} }, socket) do

    joining = joins |> 
      Map.keys |> # we want to get user_name stored as key
      Enum.map(fn user -> %{uuid: UUID.uuid4(), message: "#{user} joining the chat", user: "System" }  end)
    
    user_precence = ChatWeb.Presence.list(socket.assigns.topic) |> Map.keys
    # Logger.info(Map.keys())
    leaving = leaves |> 
      Map.keys |> # we want to get user_name stored as key
      Enum.map(fn user -> %{uuid: UUID.uuid4(), message: "#{user} left the chat", user: "System" }  end)
    {:noreply, assign(socket, messages: joining ++ leaving, users: user_precence )}

  end
  

end
