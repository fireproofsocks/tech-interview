defmodule AuctionApi.Auction do
  @moduledoc """
  A Genserver to run an auction. Terminates after the amount of seconds specified
  in its `:duration`.
  """
  use Ecto.Schema
  use GenServer

  alias AuctionApi.Bids
  alias Phoenix.PubSub

  import Ecto.Changeset

  require Logger

  @primary_key false
  embedded_schema do
    field :bids, {:array, :map}
    field :completed_at, :utc_datetime
    field :current_bid, :integer
    field :duration, :integer
    field :highest_bidder, :string
    field :name, :string
    field :seconds_remaining, :integer
    field :started_at, :utc_datetime
    field :state, Ecto.Enum, values: [:running, :completed]
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
    # Register into our custom registry so we always know which auctions are running
    name = {:via, Registry, {AuctionApi.Registry, auction_name}}
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  # AuctionApi.Auction.new(%{"name" => "a", "duration" => 15})
  # TODO: replace start_link? inputs as map
  def new(%{"name" => name, "duration" => duration}) do
    # Register into our custom registry so we always know which auctions are running
    process_name = {:via, Registry, {AuctionApi.Registry, name}}

    GenServer.start_link(__MODULE__, [name: name, duration: duration, starting_bid: 1],
      name: process_name
    )
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    duration = Keyword.fetch!(opts, :duration)
    PubSub.broadcast(AuctionApi.PubSub, "auctions:updated", "Starting new auction #{name}")
    Process.send_after(self(), :end_auction, duration * 1000)

    Process.send_after(self(), :decrement_time, 1000)

    {:ok,
     %__MODULE__{
       name: name,
       state: :running,
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
    try do
      GenServer.call(auction_pid, {:bid, username})
    catch
      :exit, reason ->
        Logger.warning(inspect(reason))
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
  Gets the state of the given auction, if active, otherwise an error is returned.
  """
  @spec state(auction_pid :: pid()) :: {:ok, %__MODULE__{}} | {:error, any()}
  def state(auction_pid) when is_pid(auction_pid) do
    try do
      GenServer.call(auction_pid, :state)
    catch
      :exit, reason ->
        Logger.warning(inspect(reason))
        {:error, "That auction is not open"}
    end
  end

  def handle_call({:bid, username}, _from, %__MODULE__{} = state)
      when username == state.highest_bidder do
    {:reply, {:error, "#{username} is already the highest bidder"}, state}
  end

  def handle_call({:bid, username}, _from, %__MODULE__{} = state) do
    new_bid = Bids.minimum_bid(state.current_bid)

    state = %__MODULE__{
      state
      | bids: [%{username: username, bid: new_bid, created_at: DateTime.utc_now()} | state.bids],
        highest_bidder: username,
        current_bid: new_bid
    }

    PubSub.broadcast(AuctionApi.PubSub, "auction:#{state.name}", state)

    {:reply, {:ok, state}, state}
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:end_auction, state) do
    state = %__MODULE__{state | state: :completed, completed_at: DateTime.utc_now()}
    Logger.debug("Auction #{state.name} has ended")
    # TODO: save this somewhere?
    PubSub.broadcast(AuctionApi.PubSub, "auction:#{state.name}", state)
    # Update list of auctions
    PubSub.broadcast(AuctionApi.PubSub, "auctions:updated", "Ending auction #{state.name}")
    exit(:normal)
    {:noreply, []}
  end

  # The timer count-down
  def handle_info(:decrement_time, state) do
    seconds_remaining = seconds_remaining(state.started_at, state.duration)

    # send the next update in 1 second
    # TODO: we could adjust for jitter here by using milliseconds
    Process.send_after(self(), :decrement_time, 1000)
    PubSub.broadcast(AuctionApi.PubSub, "auction:#{state.name}", state)
    {:noreply, %__MODULE__{state | seconds_remaining: seconds_remaining}}
  end

  defp seconds_remaining(started_at, duration) do
    DateTime.diff(started_at, DateTime.utc_now(), :second) + duration
  end

  def create_changeset(attrs, _opts \\ []) do
    %__MODULE__{}
    |> cast(attrs, [:name, :duration])
    |> validate_required([:name, :duration])
    |> validate_length(:name, min: 1, max: 64)
    |> validate_number(:duration, greater_than_or_equal_to: 30)
  end
end
