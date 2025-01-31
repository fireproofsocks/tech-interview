defmodule AuctionApiWeb.AuctionController do
  use AuctionApiWeb, :controller

  alias AuctionApi.Auctions
  alias AuctionApi.Auction

  # def home(conn, _params) do
  #   # The home page is often custom made,
  #   # so skip the default app layout.
  #   render(conn, :home, layout: false)
  # end

  def index(conn, _params) do
    # text(conn, "in auctions now")
    # active_auctions = [{"a1", self()}]
    active_auctions = Auctions.list_running_auctions()
    render(conn, :auctions, active_auctions: active_auctions)
  end

  def show(conn, %{"auction_name" => auction_name}) do
    auction_pid = Auction.pid(auction_name)
    state = Auction.state(auction_pid)
    text(conn, "show auction #{inspect(state)}")
    # active_auctions = [{"a1", self()}]
    # active_auctions = Auctions.list_running_auctions()
    # render(conn, :auctions, active_auctions: active_auctions)
  end

  def create(conn, params) do
    text(conn, "create auction #{inspect(params)}")
  end
end
