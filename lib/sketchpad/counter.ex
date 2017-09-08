# defmodule Counter do

#   def inc(pid), do: send(pid, :inc)

#   def dec(pid), do: send(pid, :dec)

#   def val(pid) do
#       ref = make_ref()
#       send(pid, {:val, ref, self()})

#       receive do
#           # What is the ^ref doing here?
#           {:val, ^ref, val} -> val

#       after timeout -> exit(:timeout)
#       end
#   end


#   def start_link(initial_count \\ 0) do
#       {:ok, spawn_link(fn -> listen(initial_count) end)}
#   end

#   def listen(count) do
#       receive do
#           :inc ->
#               listen(count + 1)
#           :dec ->
#               listen(count - 1)
#           {:val, ref, sender} ->
#               send(sender, {:val, ref, count})
#               listen(count)
#           _ ->
#               :error
#               listen(count);
#       end
#   end
# end

defmodule Counter do
    use GenServer

    # API
    def inc(pid), do: GenServer.cast(pid, :inc)

    def dec(pid), do: GenServer.cast(pid, :dec)

    def val(pid) do
        GenServer.call(pid, :val)
    end

    def start_link(initial_count \\ 0) do
        # naming this allows us to do Process.whereis(Counter) when we have added this to the phoenix supervision tree
        GenServer.start_link(__MODULE__, [initial_count], name: __MODULE__)
    end

    # Server
    def init([initial_count]) do
      {:ok, initial_count}
    end

    def handle_cast(:inc, count) do
      {:noreply, count + 1}
    end

    def handle_cast(:dec, count) do
      {:noreply, count - 1}
    end

    def handle_call(:val, _from, count) do
      {:reply, count, count}
    end
end