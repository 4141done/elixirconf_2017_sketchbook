#lib/sketchpad/pad.ex

defmodule Sketchpad.Pad do
  use GenServer
  alias SketchpadWeb.Endpoint

  ## Client

  def png_ack(encoded_png) do
    # STUDY: with clause
    with {:ok, decoded_png} <- Base.decode64(encoded_png),
          # STUDY: briefly
         {:ok, path} <- Briefly.create(),
         {:ok, jpeg_path} <- Briefly.create(),
         :ok <- File.write(path, decoded_png),
         args = ["-background", "white", "-flatten", path, "jpg:" <> jpeg_path],
         {"", 0} <- System.cmd("convert", args),
         {ascii, 0} <- System.cmd("jp2a", ["-i", jpeg_path]) do
      
      {:ok, ascii}
    else

      _ -> :error
    end
  end

  def find!(pad_id) do
    case Registry.lookup(Sketchpad.Registry, topic(pad_id)) do
      [{pid, _}] -> pid
      [] -> raise ArgumentError, "no process found for pad id #{inspect pad_id}"
    end
  end

  def clear(pad_id) do
    pad_id
    |> find!()
    |> GenServer.call(:clear)
  end

  def render(pad_id) do
    pad_id
    |> find!()
    |> GenServer.call(:render)
  end

  def put_stroke(pad_id, user_id, stroke, publisher) do
    pad_id
    |> find!()
    |> GenServer.call({:put_stroke, user_id, stroke, publisher})
  end

  ## Server

  def start_link(pad_id) do
    GenServer.start_link(__MODULE__, [pad_id],
      name: {:via, Registry, {Sketchpad.Registry, topic(pad_id)}})
  end


  defp schedule_png_request do
    Process.send_after(self(), :request_png, 3_000)
  end

  def init([pad_id]) do
    schedule_png_request()
    state = %{
      pad_id: pad_id,
      topic: topic(pad_id),
      users: %{}
    }

    {:ok, state}
  end

  def handle_info(:request_png, state) do
    case SketchpadWeb.Presence.list(state.topic) do
      users when map_size(users) > 0 ->
        # Here we grab a reference to a random user and broadcast to that topic
        # When each PadChannel process starts up it subscribes to the topic which
        # is the pad and : its ref.  So this broadcast will target a process with a
        # channel to a specific users' browser
        {user_id, %{metas: [%{phx_ref: ref} | _]}} = Enum.random(users)

        Endpoint.broadcast!(state.topic <> ":#{ref}", "png_request", %{})
      _ -> :noop
    end
    schedule_png_request()
    {:noreply, state}
  end

  def handle_call(:render, _from, state) do
    {:reply, state.users, state}
  end

  def handle_call(:clear, _from, state) do
    Endpoint.broadcast!(state.topic, "clear", %{})
    {:reply, :ok, %{state | users: %{}}}
  end

  def handle_call({:put_stroke, user_id, stroke, publisher}, _from, state) do
    Endpoint.broadcast_from!(publisher, state.topic, "stroke", %{
      user_id: user_id,
      stroke: stroke
    })

    {:reply, :ok, put_user_stroke(state, user_id, stroke)}
  end

  defp put_user_stroke(%{users: users} = state, user_id, stroke) do
    users =
      users
      |> Map.put_new_lazy(user_id, fn -> %{id: user_id, strokes: []} end)
      |> update_in([user_id, :strokes], fn strokes -> [stroke | strokes] end)

    %{state | users: users}
  end


  defp topic(pad_id), do: "pad:#{pad_id}"
end