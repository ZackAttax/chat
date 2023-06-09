defmodule ChatWeb.TopicLive do
  use ChatWeb, :live_view
  require Logger

  def mount(%{"topic_name" => topic_name}, _session, socket) do
    name = AnonymousNameGenerator.generate_random()
      |> String.split("-")
      |> Enum.map(fn word -> word |> String.capitalize() end)
      |> Enum.join(" ")
    user = %{name: name, id: Base.encode64(:crypto.strong_rand_bytes(10))}
    if connected?(socket) do
      ChatWeb.Endpoint.subscribe(topic_name)
      ChatWeb.Presence.track(self(), topic_name, user[:name], %{})
    end

    socket = socket
      |> stream(:chat_data, [])
      |> assign(:users_online, [])
      |> assign(topic_name: topic_name)
      |> assign(chat: to_form(%{}))
      |> assign(username: user.name)
      |> assign(topic_name: topic_name)
      |> assign(message: "")
      |> assign(users: [])

    {:ok, socket}
  end

  def handle_event("goto_topic", %{"topic_name" => topic_name}, socket) do
    topic_link = "/" <> topic_name
    {:noreply, push_redirect(socket, to: topic_link)}
  end

  def handle_event("submit_message", %{"chat_input" => message}, socket) do
    message_data = %{
      message: message,
      username: socket.assigns.username,
      id: Base.encode64(:crypto.strong_rand_bytes(10))
    }
    ChatWeb.Endpoint.broadcast(socket.assigns.topic_name, "new_message", message_data)

    {:noreply, assign(socket, message: "")}
  end

  def handle_event("message_change", %{"chat_input" => message}, socket) do

    {:noreply, assign(socket, message: message)}
  end

  def handle_info(%{event: "new_message", payload: message_data}, socket) do
    {:noreply, stream_insert(socket, :chat_data, message_data, at: -1)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    users_online = ChatWeb.Presence.list(socket.assigns.topic_name) |> Map.keys()
    Logger.info(presence_diff: users_online)
    socket = socket
      |> assign(users_online: users_online)

    {:noreply, socket}
  end

  def user_msg_heex(assigns) do
    ~H"""
    <li id={@msg.id} class={"relative #{if @msg.username == @me, do: "bg-white ml-40", else: "bg-green-300 mr-40"} mb-2 py-5 px-4 border rounded-xl"}>
      <div class="flex justify-between space-x-3">
      <div class="min-w-0 flex-1">
          <a href="#" class="block focus:outline-none">
          <span class="absolute inset-0" aria-hidden="true"></span>
          <p class="truncate text-sm font-medium text-gray-900 mb-4"><%= @msg.username %></p>
          </a>
      </div>
      </div>
      <div class="mt-1">
      <p class="text-sm text-gray-600 line-clamp-2"><%= @msg.message %> </p>
      </div>
    </li>
    """
  end
end
