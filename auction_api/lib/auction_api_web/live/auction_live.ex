defmodule AuctionApiWeb.AuctionLive do
  use AuctionApiWeb, :live_view
  alias AuctionApi.Auction
  alias Phoenix.PubSub

  def mount(%{"auction_name" => auction_name}, _session, socket) do
    # dbg(socket)

    if connected?(socket) do
      PubSub.subscribe(AuctionApi.PubSub, "auction:#{auction_name}")
      PubSub.subscribe(AuctionApi.PubSub, "auction:#{auction_name}:completed")
    end

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

    auction_state
    |> Map.from_struct()
    |> Map.put(:current_user, socket.assigns.current_user)
  end

  def render(%{state: :completed} = assigns) do
    # dbg(assigns)

    ~H"""
    <h2 class="text-[2rem] mt-4 font-semibold leading-10 tracking-tighter text-zinc-900 text-balance">
      Auction {@name} completed!
    </h2>
    <div id="auction">
      <div>Winning bid: ${@current_bid}</div>
      <%= if @highest_bidder == assigns.current_user.email do %>
        <div>Congratulations! You won the auction!</div>
      <% else %>
        <div>Highest bidder: {@highest_bidder}</div>
      <% end %>
    </div>
    """
  end

  def render(assigns) do
    # dbg(assigns)

    ~H"""
    <h2 class="text-[2rem] mt-4 font-semibold leading-10 tracking-tighter text-zinc-900 text-balance">
      Auction {@name}
    </h2>
    <div id="auction">
      <div>Seconds remaining: {to_hh_mm_ss(@seconds_remaining)}</div>
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

  # TODO: move to dedicated module
  def to_hh_mm_ss(0), do: "0:00"

  def to_hh_mm_ss(seconds) do
    units = [3600, 60, 1]

    [h | t] =
      Enum.map_reduce(units, seconds, fn unit, val -> {div(val, unit), rem(val, unit)} end)
      |> elem(0)
      |> Enum.drop_while(&match?(0, &1))

    {h, t} = if length(t) == 0, do: {0, [h]}, else: {h, t}

    "#{h}:#{t |> Enum.map_join(":", fn x -> x |> Integer.to_string() |> String.pad_leading(2, "0") end)}"
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

  # Receive pubsub messages here
  def handle_info(%Auction{} = auction_state, socket) do
    # dbg(auction_state)

    assigns =
      auction_state
      |> Map.from_struct()
      |> Map.put(:current_user, socket.assigns.current_user)

    {:noreply, assign(socket, assigns)}
  end

  def handle_info(_pubsub_msg, socket) do
    auction_pid = Auction.pid(socket.assigns.name)
    {:noreply, assign(socket, state_to_assigns(auction_pid, socket))}
  end
end
