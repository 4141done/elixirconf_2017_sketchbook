# Source for many of the convenience methods shown here: https://github.com/phoenixframework/phoenix/blob/master/lib/phoenix/test/channel_test.ex
defmodule SketchpadWeb.PadChannelTest do
	use SketchpadWeb.ChannelCase

	alias SketchpadWeb.UserSocket

	describe "connecting and joining" do
		test "invalid tokens deny connection" do
			assert :error = connect(UserSocket, %{"token" => "invalid", "color" => "something"})
		end

		test "valid tokens verify and connect user" do
			valid_token = Phoenix.Token.sign(@endpoint, "user token", "a-user")
			assert {:ok, socket} = connect(UserSocket, %{"token" => valid_token, "color" => "something"})
			assert socket.assigns.user_id == "a-user"

		end
	end

	describe "after join" do
		setup do
			{:ok, _, socket} =
				socket("123", %{})
				|> Phoenix.Socket.assign(:user_id, "123")
				|> subscribe_and_join(SketchpadWeb.PadChannel, "pad:lobby", %{})
			{:ok, socket: socket}
		end

		test "pushing clear event broadcasts to all peers", %{socket: socket} do
			ref = push socket, "clear", %{}

			assert_reply ref, :ok
		end

		test "presence list is sent on join", %{socket: socket} do
			assert_push "presence_state", %{}
			assert_broadcast "presence_diff", %{joins: %{"123" => _}}
		end
	end
end