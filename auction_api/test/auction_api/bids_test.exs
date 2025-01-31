defmodule AuctionApi.BidsTest do
  use ExUnit.Case, async: false
  alias AuctionApi.Bids

  describe "power_of_10/1" do
    test "1 when number is less than 100" do
      assert 1 = Bids.power_of_10(90)
    end

    test "2 when number is 100 or greater" do
      assert 2 = Bids.power_of_10(100)
    end
  end

  describe "minimum_increment/1" do
    test "1 when bid is 90" do
      assert 1 = Bids.minimum_increment(90)
    end

    test "10 when bid is 100" do
      assert 10 = Bids.minimum_increment(100)
    end

    test "1 when bid is 1" do
      assert 1 = Bids.minimum_increment(1)
    end
  end

  describe "minimum_bid/1" do
    test "91 when bid is 90" do
      assert 91 = Bids.minimum_bid(90)
    end

    test "110 when bid is 100" do
      assert 110 = Bids.minimum_bid(100)
    end
  end
end
