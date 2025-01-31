defmodule AuctionApiWeb.AuctionsIndexLive do
  use AuctionApiWeb, :live_view

  alias AuctionApi.Auctions

  def mount(_params, _session, socket) do
    {:ok, assign(socket, active_auctions: Auctions.list_running_auctions())}
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 py-10 sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32">
      <div class="mx-auto max-w-xl lg:mx-0">
        <ul>
          <%= for {auction_name, _} <- @active_auctions do %>
            <li>
              <.link navigate={~p"/auctions/#{auction_name}"}>
                {auction_name}
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  #   def render(assigns) do
  #   ~H"""
  #   <div class="px-4 py-10 sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32">
  #     <div class="mx-auto max-w-xl lg:mx-0">
  #       <ul>
  #         <%= for {auction_name, _} <- @active_auctions do %>
  #           <li>
  #             <.link phx-click="show_auction" phx-value-auction_name={auction_name}>
  #               {auction_name}
  #             </.link>
  #           </li>
  #         <% end %>
  #       </ul>
  #     </div>
  #   </div>
  #   """
  # end

  # def handle_event("show_auction", %{"auction_name" => auction_name}, socket) do
  #   IO.puts("SHOW AUCTION")
  #   dbg(value)
  #   {:noreply, socket}
  # end
end
