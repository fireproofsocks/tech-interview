defmodule AuctionApiWeb.AuctionLive do
  use AuctionApiWeb, :live_view
  alias AuctionApi.Auction

  def mount(%{"auction_name" => auction_name}, _session, socket) do
    # pid = Auction.pid()
    # state = Auction.state(pid)
    Process.send_after(self(), :decrement_time, 1000)

    auction_state =
      auction_name |> Auction.pid() |> Auction.state()

    seconds_remaining = seconds_remaining(auction_state.started_at, auction_state.duration)

    assigns =
      auction_state
      |> Map.from_struct()
      |> Map.put(:seconds_remaining, seconds_remaining)
      |> Map.to_list()

    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <h1><%= @name %></h1>
    <div id="auction">
      <div>Seconds remaining: <%= @seconds_remaining %></div>
      <div>Highest bid: <%= @current_bid %>.</div>
      <div>Highest bidder: <%= @highest_bidder %></div>
      <button phx-click="bid" phx-value-auction_name={@name} phx-value-username="SOMEUSER">
        Place Bid
      </button>
    </div>
    """
  end

  def handle_event("bid", %{"auction_name" => auction_name, "username" => username}, socket) do
    # dbg(value)
    auction_pid = Auction.pid(auction_name)
    IO.puts("PLACING BID")

    case Auction.bid(auction_pid, username) do
      {:ok, state} ->
        {:noreply,
         assign(socket, current_bid: state.current_bid, highest_bidder: state.highest_bidder)}

      _ ->
        {:noreply, socket}
    end

    # {:noreply, socket}
  end

  def handle_info(:decrement_time, socket) do
    seconds_remaining = seconds_remaining(socket.assigns.started_at, socket.assigns.duration)

    # send the next update in 1 second
    Process.send_after(self(), :decrement_time, 1000)
    {:noreply, assign(socket, seconds_remaining: seconds_remaining)}
  end

  defp seconds_remaining(started_at, duration) do
    DateTime.diff(started_at, DateTime.utc_now(), :second) + duration
  end
end
