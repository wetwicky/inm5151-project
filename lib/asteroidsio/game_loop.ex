defmodule Asteroidsio.GameLoop do
  use GenServer
  require Graphmath.Vec2
  import Asteroidsio.Player
  import Asteroidsio.Asteroid

  ## Client API

  def tick({k, v}) do
    case {k, v} do
      {:id, _} ->
        {k, v}

      {id, %{:type => :player,
             :x => x,
             :y => y,
             :direction => dir,
             :dx => dx,
             :dy => dy,
             :up_pressed => up_pressed,
             :left_pressed => left_pressed,
             :right_pressed => right_pressed,
             :fire_pressed => fire_pressed,
             :last_time_fired => last_time_fired,
             :last_update => last_update,
             :bullets => bullets,
             :score => score,
             :health => health
            }} ->
        updatePlayers(id,
          v,
          x,
          y,
          dir,
          dx,
          dy,
          up_pressed,
          left_pressed,
          right_pressed,
          fire_pressed,
          last_time_fired,
          last_update,
          bullets,
          score,
          health)

      {id, %{:type => :asteroid,
             :x => x,
             :y => y,
             :direction => dir,
             :speed => speed,
             :last_update => last_update
            }} ->
        updateAsteroid(id,
          v,
          x,
          y,
          dir,
          speed,
          last_update)

      {id, v} ->
        {id, v}
    end
  end

  ## Server API

  def start_link(name) do
    GenServer.start_link(__MODULE__, [], name: name)
  end

  def init(_) do
    {:ok, %{:timer => schedule_work(), :timerTopTen => schedule_top_ten(), :timerSlowWork => schedule_slow_work()}}
  end

  def handle_info(:tick, state) do
    timerRef = schedule_work()
    bucket = Map.drop(Asteroidsio.Bucket.update_all(&tick/1), [:id])

    Asteroidsio.PlayerChannel.update_entities(bucket)
    {:noreply, %{state | :timer => timerRef}}
  end

  def handle_info(:tickTopTen, state) do
    timerRef = schedule_top_ten()
    bucket = Asteroidsio.Bucket.current
    players = Enum.filter(bucket, fn({_, v}) -> v != nil && v != %{} && v.type == :player end)
    sortedPlayers = Enum.sort(players, fn({_, v1}, {_, v2}) -> v1.score > v2.score end)
    parsedPlayers = Enum.map(sortedPlayers, fn({_, v}) -> %{:name => v.name, :score => v.score} end)
    topTen = Enum.take(parsedPlayers, 10)

    Asteroidsio.PlayerChannel.update_top_ten(%{:data => topTen})

    {:noreply, %{state | :timerTopTen => timerRef}}
  end

  def handle_info(:tickSlowWork, state) do
    timerRef = schedule_slow_work()
    bucket = Asteroidsio.Bucket.current
    nils = Enum.filter(bucket, fn({_, v}) -> v == nil || v == %{} end)
    Enum.map(nils, fn({id, _}) -> Asteroidsio.Bucket.delete(id) end)
    players = Enum.filter(bucket, fn({_, v}) -> v.type == :player end)
    asteroids = Enum.filter(bucket, fn({_, v}) -> v.type == :asteroid end)
    createAsteroids(players, asteroids)
    deleteAsteroids(players, asteroids)

    {:noreply, %{state | :timerSlowWork => timerRef}}
  end

  def code_change(_old, state, _extra) do
    Process.cancel_timer(state.timer)
    {:ok, %{}}
  end

  def terminate(reason, state) do
    IO.puts "Asked to stop because #{inspect reason} with state #{inspect state}"
    Process.cancel_timer(state.timer)
    :ok
  end

  defp schedule_work() do
    Process.send_after(self(), :tick, trunc(1000/30)) # 30 times per second
  end

  defp schedule_top_ten() do
    Process.send_after(self(), :tickTopTen, trunc(1000)) # 1 time per second
  end

  defp schedule_slow_work() do
    Process.send_after(self(), :tickSlowWork, trunc(10000)) # 1 time per 10 seconds
  end
end
