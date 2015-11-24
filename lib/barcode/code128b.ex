defmodule Barcode.Code128b do
  import String, only: [graphemes: 1, duplicate: 2]
  import Enum, only: [map: 2, find_index: 2]
  import List, only: [foldl: 3]

  # Code 128B characters 0-94
  @char graphemes(" !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrst" <>
                  "uvwxyz{|}~")
  # Code 128 values 0-102, expressed as bitfields
  @code {1740, 1644, 1638, 1176, 1164, 1100, 1224, 1220, 1124, 1608, 1604, 1572, 1436, 1244, 1230, 1484, 1260,
         1254, 1650, 1628, 1614, 1764, 1652, 1902, 1868, 1836, 1830, 1892, 1844, 1842, 1752, 1734, 1590, 1304,
         1112, 1094, 1416, 1128, 1122, 1672, 1576, 1570, 1464, 1422, 1134, 1496, 1478, 1142, 1910, 1678, 1582,
         1768, 1762, 1774, 1880, 1862, 1814, 1896, 1890, 1818, 1914, 1602, 1930, 1328, 1292, 1200, 1158, 1068,
         1062, 1424, 1412, 1232, 1218, 1076, 1074, 1554, 1616, 1978, 1556, 1146, 1340, 1212, 1182, 1508, 1268,
         1266, 1956, 1940, 1938, 1758, 1782, 1974, 1400, 1310, 1118, 1512, 1506, 1960, 1954, 1502, 1518, 1886,
         1966}
  @start 1680
  @stop <<6379::size(13)>>
  @lines {"█", "▌", "▐", " "}

  @doc """
  Create a white on black printable format of a barcode, with appropriate quiet zones.

      iex> Barcode.Code128b.printable("Wikipedia")
      "\███████████████████████████████████████████████████████████████████████████\n\
      ████ ▌█▐█▌ ▌█▌▐▐█▌▐▐▌▐█▌█▐▐█▌▐▐▌▌█  █▐ █▐█▌██▐▌▐▐█▌▐▐▌█▐ ██  █▐▌▌▐█ ▐▐ ████\n\
      ████ ▌█▐█▌ ▌█▌▐▐█▌▐▐▌▐█▌█▐▐█▌▐▐▌▌█  █▐ █▐█▌██▐▌▐▐█▌▐▐▌█▐ ██  █▐▌▌▐█ ▐▐ ████\n\
      ████ ▌█▐█▌ ▌█▌▐▐█▌▐▐▌▐█▌█▐▐█▌▐▐▌▌█  █▐ █▐█▌██▐▌▐▐█▌▐▐▌█▐ ██  █▐▌▌▐█ ▐▐ ████\n\
      ████ ▌█▐█▌ ▌█▌▐▐█▌▐▐▌▐█▌█▐▐█▌▐▐▌▌█  █▐ █▐█▌██▐▌▐▐█▌▐▐▌█▐ ██  █▐▌▌▐█ ▐▐ ████\n\
      ███████████████████████████████████████████████████████████████████████████\n\
      "
  """
  def printable(string, height \\ 4, inverse \\ true) do
    quiet = if inverse, do: elem(@lines, 0), else: elem(@lines, 3)
    code = duplicate(quiet, 4) <> to_box_chars(encode(string), inverse) <> duplicate(quiet, 4) <> "\n"
    blank = duplicate(quiet, String.length(code) - 1) <> "\n"
    blank <> duplicate(code, height) <> blank
  end

  @doc """
  Create a bitstring of 1 = dark, 0 = light values in Code 128b. Only a subset of ascii is supported.
  Characters unsupported by Code128b will be replaces with spaces.

      iex> Barcode.Code128b.encode("Wikipedia")
      <<210, 29, 26, 26, 97, 40, 105, 79, 44, 132, 38, 134, 146, 195, 201, 99, 43::size(6)>>
  """
  def encode(string) do
    {bin, _, sum} =
    graphemes(string)
    |> foldl({<<@start::size(11)>>, 1, 1}, fn(char, {bin, i, sum}) ->
      index = Enum.find_index(@char, &(&1 == char)) || 0
      {<<bin::bitstring, elem(@code, index)::size(11)>>, i+1, sum + i * index}
    end)
    <<bin::bitstring, elem(@code, rem(sum, 103))::size(11), @stop::bitstring>>
  end

  defp to_box_chars(_, _ \\ "", _)
  defp to_box_chars(<<>>, out, _), do: out
  defp to_box_chars(<<bit::size(1)>>, out, inv), do: to_box_chars(<<bit::size(1), 0::size(1)>>, out, inv)
  defp to_box_chars(<<val::size(2), bin::bitstring>>, out, true) do
    to_box_chars(bin, out <> elem(@lines, val), true)
  end
  defp to_box_chars(<<val::size(2), bin::bitstring>>, out, false) do
    to_box_chars(bin, out <> elem(@lines, 3-val), false)
  end
end
