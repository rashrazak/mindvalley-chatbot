defmodule ChatWeb.BotsLive do
    # any controller need a same html name
    use ChatWeb, :live_view
    require Logger

    @impl true
    # def mount(%{"id" => user}, _session, socket) do #pattern matching
    def mount(params, _session, socket) do
        %{"id" => user} = params
        topic = "chatbots"
        if connected?(socket) do
        ChatWeb.Endpoint.subscribe(topic)
        end
        {:ok, assign(socket, user: user,
        topic: topic,
        chat_type: "",
        message: "",
        messages: [],
        coins: [],
        chart: [],
        temporary_assigns: [messages: []]
        )}
    end

    @impl true
    def handle_event("start-chat",  %{}, socket) do
        ChatWeb.Presence.track(self(), socket.assigns.topic, socket.assigns.user, %{})
        {:noreply, socket}
    end

    @impl true
    def handle_event("input-message", %{"chat" => %{"message" => message}}, socket) do
    # def handle_event("submit-message", params, socket) do
        Logger.info(input: message)
        {:noreply, assign(socket, message: message)}
    end

    @impl true
    def handle_event("submit-message", %{"chat" => %{"message" => message}}, socket) do

        ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", %{uuid: UUID.uuid4() , user: socket.assigns.user, message: message})

        coinArray = cond do
            String.contains?(message, "coin-") ->
                [_,qry] = String.split(message, "-")
                case HTTPoison.get("https://api.coingecko.com/api/v3/search?query=#{qry}") do
                    {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                        %{"coins" => coins} = Jason.decode!(body)
                        coinsArr = coins |> Enum.take(5)
                        ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", %{uuid: UUID.uuid4() , user: "System", chat_type: "lists", message: "Here are the top 5
                        based on the market cap rank", coins: coinsArr})
                        :timer.sleep(2000)
                        ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", %{uuid: UUID.uuid4() , user: "System",
                        chat_type: "text", message: "Please select the symbol for retrieve coin prices (last 14 days) :: select-[symbol] eg: select-ETH"})
                        coinsArr
                    {:ok, %HTTPoison.Response{status_code: 404}} ->
                        ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", %{uuid: UUID.uuid4() , user: "System", chat_type: "text", message: "Sorry :( something wrong. please input your Coin with coin-[search],eg: coin-solana"})
                        nil
                end
            String.contains?(message, "select-") ->
                [_,qry] = String.split(message, "-")
                crypto = Enum.find(socket.assigns.coins, fn %{"symbol" => symbol} -> symbol == qry  end)
                :timer.sleep(2000)
                case HTTPoison.get("https://api.coingecko.com/api/v3/coins/#{crypto["id"]}/market_chart?vs_currency=usd&days=14&interval=daily") do
                    {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                        %{"market_caps" => _, "prices" => y, "total_volumes" => _} = Jason.decode!(body)
                        new_y = Enum.map(y, fn [a, b] -> [convert_datetime(a), Kernel.round(b)] end)
                        ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", %{uuid: UUID.uuid4() , user: "System", chat_type: "chart_lists", message: "Here are the prices for the last 14 days", chart: new_y})
                        # :timer.sleep(2000)
                        # ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", %{uuid: UUID.uuid4() , user: "System",
                        # chat_type: "text", message: "Please select between 1..5 select-[number] eg: select-1"})
                        nil
                    {:ok, %HTTPoison.Response{status_code: 404}} ->
                        ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", %{uuid: UUID.uuid4() , user: "System", chat_type: "text", message: "Sorry :( something wrong. please input your Coin with coin-[search],eg: coin-solana"})
                        nil
                end
            true ->
                ChatWeb.Endpoint.broadcast(socket.assigns.topic, "new-message", %{uuid: UUID.uuid4() , user: "System", chat_type: "text", message: "please input your Coin with coin-[search],eg: coin-solana"})
        end
        if coinArray == nil do
            {:noreply, assign(socket, message: "")}
        else
            {:noreply, assign(socket, message: "", coins: coinArray)}
        end

    end

    @impl true
    def handle_info(%{ event: "presence_diff", payload: %{joins: joins} }, socket) do
        welcome = joins |>
        Map.keys |> # we want to get user_name stored as key
        Enum.map(fn user -> %{uuid: UUID.uuid4(), message: "Welcome to the chat #{user}, please input your Coin search with coin-[search]", user: "System",  chat_type: "text"}  end)
        Logger.info(welcome)
        {:noreply, assign(socket, messages: welcome )}
    end

    @impl true
    def handle_info(%{ event: "new-message", payload: message }, socket) do
        Logger.info(payload: message)
        {:noreply, assign(socket, messages: [message])}
    end

    defp convert_datetime(d) do
        {:ok, datetime} = DateTime.from_unix(d, :millisecond)
        [x, y, z] = Date.to_iso8601(datetime) |> String.split("-")
        "#{z}/#{y}/#{x}"
    end
end
