defmodule AuctionApi.Auctions do
  @moduledoc """
  Context module for interacting with Auctions
  """

  @spec list_running_auctions() :: [{binary(), pid()}]
  @doc """
  Lists all running auctions. Result is a list of tuples containing the auction name
  and its pid

  ## Examples

      iex> AuctionApi.Auction.list_running_auctions()
      []
  """
  def list_running_auctions do
    Registry.select(AuctionApi.Registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2"}}]}])
  end
end
