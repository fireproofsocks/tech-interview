defmodule AuctionApiWeb.AuctionsIndexLive do
  use AuctionApiWeb, :live_view

  alias AuctionApi.Auctions
  alias Phoenix.PubSub
  # alias AuctionApi.Users

  # see https://hexdocs.pm/phoenix_live_view/0.18.13/security-model.html
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(AuctionApi.PubSub, "auctions:updated")
    end

    {:ok, assign(socket, active_auctions: Auctions.list_running_auctions())}
  end

  # Receive pubsub messages here
  def handle_info(_pubsub_msg, socket) do
    {:noreply, assign(socket, active_auctions: Auctions.list_running_auctions())}
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 py-10 sm:px-6 sm:py-28 lg:px-8 xl:px-28 xl:py-32">
      <div class="mx-auto max-w-xl lg:mx-0">
        <h2 class="text-[2rem] mt-4 font-semibold leading-10 tracking-tighter text-zinc-900 text-balance">
          Running Auctions
        </h2>
        <%= if @active_auctions == [] do %>
          <p>There are currently no auctions running.</p>
        <% else %>
          <ul>
            <%= for {auction_name, _} <- @active_auctions do %>
              <li>
                <.link navigate={~p"/auctions/#{auction_name}"}>
                  {auction_name}
                </.link>
              </li>
            <% end %>
          </ul>
        <% end %>
      </div>
      <div class="mx-auto max-w-xl lg:mx-0">
        <h2 class="text-[2rem] mt-4 font-semibold leading-10 tracking-tighter text-zinc-900 text-balance">
          Create new Auction
        </h2>
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
