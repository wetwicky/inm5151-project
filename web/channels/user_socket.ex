defmodule Asteroidsio.UserSocket do
  use Phoenix.Socket
  import Asteroidsio.Bucket

  ## Channels
  channel "player:*", Asteroidsio.PlayerChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket, timeout: 45_000
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(params, socket) do
    x = Enum.random(-400..400)
    y = Enum.random(-400..400)
    player_id = add(%{
        :type => :player,
        :name => params["name"] |> String.slice(0,15),
        :x => x,
        :y => y,
        :direction => 90,
        :dx => 0,
        :dy => 0,
        :last_update => nil,
        :bullets => [],
        :last_time_fired => nil,
        :score => 0,
        :health => 50,
        :last_hit => nil
    })

    {:ok, assign(socket, :player_id, player_id)}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "users_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Asteroidsio.Endpoint.broadcast("users_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  #def id(_socket), do: nil
  def id(socket), do: "users_socket:#{socket.assigns.player_id}"

end
