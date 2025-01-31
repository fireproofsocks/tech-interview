defmodule AuctionApi.Bids do
  @moduledoc """
  Houses logic about bids
  """

  @doc """
  Calculates the minimum bid given the current_bid.

  The minimum increment is the previous power of ten.
  Example: if the current bid is $90, the next minimum bid is $91.
  If the current bid is $100, the next minimum bid is $110.
  """
  def minimum_bid(current_bid) when is_number(current_bid) do
    current_bid + minimum_increment(current_bid)
  end

  @doc """
  Apply our logic of the "previous power of 10" while maintaining
  a minimum of $1 increments.
  """
  def minimum_increment(current_bid) when is_number(current_bid) do
    bid = 10 ** (power_of_10(current_bid) - 1)

    if bid < 1 do
      1
    else
      bid
    end
  end

  @doc """
  Given a number, this returns the truncated log base 10.
  This means we are getting a read on the general size of the number.
  """
  @spec power_of_10(float() | integer()) :: integer()
  def power_of_10(number) when is_number(number) do
    number |> ElixirMath.log10() |> trunc()
  end
end
