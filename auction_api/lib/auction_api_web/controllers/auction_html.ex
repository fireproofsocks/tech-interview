defmodule AuctionApiWeb.AuctionHTML do
  @moduledoc """
  This module contains pages rendered by AuctionController.

  See the `page_html` directory for all templates available.
  """
  use AuctionApiWeb, :html

  embed_templates "auction_html/*"
end
