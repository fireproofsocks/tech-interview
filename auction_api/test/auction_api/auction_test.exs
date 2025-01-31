defmodule AuctionApi.AuctionTest do
  use ExUnit.Case, async: false
  alias AuctionApi.Auction
  alias Ecto.Changeset

  describe "create_changeset/2" do
    test "valid" do
      assert %Changeset{valid?: true} =
               Auction.create_changeset(%{"duration" => 30, "name" => "foo"})
    end

    test "invalid" do
      assert %Changeset{valid?: false} =
               Auction.create_changeset(%{"duration" => 1, "name" => "foo"})
    end
  end
end
