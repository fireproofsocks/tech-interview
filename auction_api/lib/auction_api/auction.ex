defmodule AuctionApi.Auction do
  @moduledoc """
  A Genserver to run an auction. Terminates after
  """
  use GenServer

  alias AuctionApi.Bids

  defmodule State do
    defstruct [:name, :duration, :bids, :current_bid, :highest_bidder, :started_at, :completed_at]
  end

  @doc """
  We register the pid into the custom `AuctionApi.Registry` so we can look up pids later by
  auction name.

  ## Options
  - `duration`: integer in seconds for how long the auction lasts
  - `starting_bid`: integer dictating the starting bid for the auction

  ## Examples

      iex> {:ok, auction_pid} AuctionApi.Auction.start_link(name: "a1", starting_bid: 1, duration: 30)

      AuctionApi.Auction.start_link(name: "a", starting_bid: 1, duration: 60)
      AuctionApi.Auction.start_link(name: "b", starting_bid: 1, duration: 60)
      AuctionApi.Auction.start_link(name: "c", starting_bid: 1, duration: 60)
  """
  def start_link(opts \\ []) do
    auction_name = Keyword.fetch!(opts, :name)
    name = {:via, Registry, {AuctionApi.Registry, auction_name}}
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    duration = Keyword.fetch!(opts, :duration)
    Process.send_after(self(), :end_auction, duration * 1000)

    {:ok,
     %State{
       name: Keyword.fetch!(opts, :name),
       duration: duration,
       current_bid: Keyword.fetch!(opts, :starting_bid),
       bids: [],
       highest_bidder: nil,
       started_at: DateTime.utc_now()
     }}
  end

  @doc """
  Has the specified user (identified by name) place a bid on the given auction.

  The bid amount is calculated by `AuctionApi.Bids.minimum_bid/1`

  ## Examples

      iex> {:ok, auction_pid} = AuctionApi.Auction.start_link(name: "a1", starting_bid: 1, duration: 10)
      iex> AuctionApi.Auction.bid(auction_pid, "joe")
      iex> AuctionApi.Auction.bid(auction_pid, "bob")

  """
  @spec bid(auction_pid :: pid(), username :: String.t()) ::
          {:ok, any()} | {:error, String.t()}
  def bid(auction_pid, username) when is_pid(auction_pid) and is_binary(username) do
    if Process.alive?(auction_pid) do
      GenServer.call(auction_pid, {:bid, username})
    else
      {:error, "That auction is not open"}
    end
  end

  @doc """
  Lookup the pid of an auction by its name
  """
  def pid(auction_name) do
    case Registry.lookup(AuctionApi.Registry, auction_name) do
      [{auction_pid, _}] -> auction_pid
      [] -> nil
    end
  end

  @doc """
  Gets the state of the given auction
  """
  def state(auction_pid) when is_pid(auction_pid) do
    GenServer.call(auction_pid, :state)
  end

  def handle_call({:bid, username}, _from, %State{} = state)
      when username == state.highest_bidder do
    {:reply, {:error, "#{username} is already the highest bidder"}, state}
  end

  def handle_call({:bid, username}, _from, %State{} = state) do
    new_bid = Bids.minimum_bid(state.current_bid)

    state = %State{
      state
      | bids: [{username, new_bid} | state.bids],
        highest_bidder: username,
        current_bid: new_bid
    }

    {:reply, {:ok, state}, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:end_auction, state) do
    state = %State{state | completed_at: DateTime.utc_now()}
    IO.inspect(state, label: "Auction is over")
    # TODO: save this somewhere?
    exit(:normal)
    {:noreply, []}
  end
end
