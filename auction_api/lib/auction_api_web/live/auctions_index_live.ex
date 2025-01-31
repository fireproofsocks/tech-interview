defmodule AuctionApiWeb.AuctionsIndexLive do
  use AuctionApiWeb, :live_view

  alias AuctionApi.Auction
  alias AuctionApi.Auctions
  alias Ecto.Changeset
  alias Phoenix.PubSub

  # see https://hexdocs.pm/phoenix_live_view/0.18.13/security-model.html
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(AuctionApi.PubSub, "auctions:updated")
    end

    {:ok,
     assign(socket,
       active_auctions: Auctions.list_running_auctions(),
       form: to_form(%{"name" => "", "duration" => 30})
     )}
  end

  # Receive pubsub messages here
  def handle_info(_pubsub_msg, socket) do
    {:noreply,
     assign(socket,
       active_auctions: Auctions.list_running_auctions(),
       form: to_form(%{"name" => "", "duration" => 30})
     )}
  end

  def render(assigns) do
    # dbg(assigns, limit: :infinity, printable_limit: :infinity, pretty: true)

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
        <.simple_form for={@form} phx-submit="create_auction" id="create_auction_form">
          <.input type="text" label="Name" field={@form[:name]} required />
          <.input type="number" label="Duration" value="30" field={@form[:duration]} required />
          <:actions>
            <button
              class="flex text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:outline-none  font-medium rounded-full text-sm p-2.5  me-2 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800"
              style=""
            >
              Create New Auction
            </button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  # See https://hexdocs.pm/phoenix_live_view/form-bindings.html
  # def handle_event("validate", params, socket) do
  #   # IO.puts("VALIDATE AUCTION #{auction_name}")
  #   IO.puts("VALIDATING AUCTION")
  #   # x = Auction.create_changeset(params)
  #   # dbg(x)

  #   form =
  #     params
  #     |> Auction.create_changeset()
  #     |> to_form(action: :validate)

  #   {:noreply, assign(socket, form: form)}

  #   # {:noreply, socket}
  # end

  # Validate only on submit
  def handle_event("create_auction", params, socket) do
    # IO.puts("VALIDATE AUCTION #{auction_name}")
    dbg(params)
    IO.puts("CREATING AUCTION")

    case Auction.create_changeset(params) do
      %Changeset{valid?: true} ->
        IO.puts("VALID CHANGESET")
        x = Auction.new(params)
        # doesn't get here? wtf?
        IO.puts("HERES WHAT HAPPENED")
        dbg(x)

        {:noreply,
         socket
         |> put_flash(:info, "Auction created")
         |> redirect(to: ~p"/auctions/#{params["name"]}")}

      changeset ->
        # IO.puts("INVALID CHANGESET")
        # dbg(changeset)
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
