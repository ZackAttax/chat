defmodule ChatWeb.TopicLive do
  use ChatWeb, :live_view
  require Logger

  def mount(params, _session, socket) do
    Logger.info(params: params)
    {:ok, assign(socket, form: to_form(%{}))}
  end

  def handle_event("goto_topic", %{"topic_name" => topic_name}, socket) do
    topic_link = "/" <> topic_name
    {:noreply, push_redirect(socket, to: topic_link)}
  end
end
