defmodule AuctionApiWeb.PageController do
  use AuctionApiWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def auctions(conn, _params) do
    # text(conn, "in auctions now")
    active_auctions = [{"a1", self()}]
    render(conn, :auctions, active_auctions: active_auctions)
  end
end
