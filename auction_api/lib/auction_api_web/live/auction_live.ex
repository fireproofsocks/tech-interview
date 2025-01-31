defmodule AuctionApiWeb.AuctionLive do
  use AuctionApiWeb, :live_view
  alias AuctionApi.Auction
  alias Phoenix.PubSub

  def mount(%{"auction_name" => auction_name}, _session, socket) do
    dbg(socket)

    if connected?(socket) do
      PubSub.subscribe(AuctionApi.PubSub, "auction:#{auction_name}")
    end

    Process.send_after(self(), :decrement_time, 1000)

    socket =
      case Auction.pid(auction_name) do
        nil ->
          socket
          |> put_flash(:error, "Auction #{auction_name} is no longer running")
          |> redirect(to: "/auctions")

        auction_pid ->
          assign(socket, state_to_assigns(auction_pid, socket))
      end

    {:ok, socket}
  end

  defp state_to_assigns(auction_pid, socket) do
    auction_state = Auction.state(auction_pid)
    seconds_remaining = seconds_remaining(auction_state.started_at, auction_state.duration)

    auction_state
    |> Map.from_struct()
    |> Map.put(:seconds_remaining, seconds_remaining)
    |> Map.put(:current_user, socket.assigns.current_user)
  end

  def render(assigns) do
    dbg(assigns)

    ~H"""
    <h1>{@name}</h1>
    <div id="auction">
      <div>Seconds remaining: {@seconds_remaining}</div>
      <div>Highest bid: ${@current_bid}</div>
      <%= if @highest_bidder == assigns.current_user.email do %>
        <div>Highest bidder: YOU!</div>
      <% else %>
        <div>Highest bidder: {@highest_bidder}</div>
      <% end %>

      <button phx-click="bid" phx-value-auction_name={@name} phx-value-username={@current_user.email}>
        Place Bid
      </button>
    </div>
    """
  end

  def handle_event("bid", %{"auction_name" => auction_name, "username" => username}, socket) do
    auction_pid = Auction.pid(auction_name)

    case Auction.bid(auction_pid, username) do
      {:ok, state} ->
        {:noreply,
         assign(socket, current_bid: state.current_bid, highest_bidder: state.highest_bidder)}

      _ ->
        {:noreply, socket}
    end
  end

  # TODO: move this into Auction for better source of truth
  def handle_info(:decrement_time, socket) do
    seconds_remaining = seconds_remaining(socket.assigns.started_at, socket.assigns.duration)

    # send the next update in 1 second
    Process.send_after(self(), :decrement_time, 1000)
    {:noreply, assign(socket, seconds_remaining: seconds_remaining)}
  end

  # Receive pubsub messages here
  def handle_info(_pubsub_msg, socket) do
    auction_pid = Auction.pid(socket.assigns.name)
    {:noreply, assign(socket, state_to_assigns(auction_pid, socket))}
  end

  defp seconds_remaining(started_at, duration) do
    DateTime.diff(started_at, DateTime.utc_now(), :second) + duration
  end
end
