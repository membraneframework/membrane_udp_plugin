defmodule Membrane.Integration.TestingPipeline do
  @moduledoc false
  use Membrane.Pipeline

  @spec message_child(pid(), atom(), atom()) :: {:for_element, atom(), atom()}
  def message_child(pipeline, child, message) do
    send(pipeline, {:for_element, child, message})
  end

  @spec receive_message(any(), non_neg_integer()) :: :ok | {:ok, any()} | {:error, :timeout}
  def receive_message(message, timeout) do
    receive do
      {__MODULE__, ^message} ->
        :ok

      {__MODULE__, {^message, payload}} ->
        {:ok, payload}
    after
      timeout ->
        {:error, :timeout}
    end
  end

  @impl true
  def handle_init(%{
        elements: elements,
        links: links,
        test_process: test_process_pid
      }) do
    spec = %Membrane.Pipeline.Spec{
      children: elements,
      links: links
    }

    {{:ok, spec}, %{test_process: test_process_pid}}
  end

  @impl true
  def handle_stopped_to_prepared(state),
    do: notify_parent(:handle_stopped_to_prepared, state)

  @impl true
  def handle_playing_to_prepared(state),
    do: notify_parent(:handle_playing_to_prepared, state)

  @impl true
  def handle_prepared_to_playing(state),
    do: notify_parent(:handle_prepared_to_playing, state)

  @impl true
  def handle_prepared_to_stopped(state),
    do: notify_parent(:handle_prepared_to_stopped, state)

  @impl true
  def handle_notification(notification, from, state),
    do: notify_parent({:handle_notification, {notification, from}}, state)

  @impl true
  def handle_other({:for_element, element, message}, state) do
    {{:ok, forward: {element, message}}, state}
  end

  def handle_other(message, state),
    do: notify_parent({:handle_other, message}, state)

  def notify_parent(message, %{test_process: parent} = state) do
    send(parent, {__MODULE__, message})

    {:ok, state}
  end
end
