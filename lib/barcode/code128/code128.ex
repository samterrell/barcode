defmodule Barcode.Code128 do
  import Barcode.Code128.Bits

  @doc """
  Create a white on black printable format of a barcode, with appropriate quiet zones.

      iex> Barcode.Code128.printable("Wikipedia") |> to_string()
      "\███████████████████████████████████████████████████████████████████████████\n\
      ████ ▌█▐█▌ ▌█▌▐▐█▌▐▐▌▐█▌█▐▐█▌▐▐▌▌█  █▐ █▐█▌██▐▌▐▐█▌▐▐▌█▐ ██  █▐▌▌▐█ ▐▐ ████\n\
      ████ ▌█▐█▌ ▌█▌▐▐█▌▐▐▌▐█▌█▐▐█▌▐▐▌▌█  █▐ █▐█▌██▐▌▐▐█▌▐▐▌█▐ ██  █▐▌▌▐█ ▐▐ ████\n\
      ████ ▌█▐█▌ ▌█▌▐▐█▌▐▐▌▐█▌█▐▐█▌▐▐▌▌█  █▐ █▐█▌██▐▌▐▐█▌▐▐▌█▐ ██  █▐▌▌▐█ ▐▐ ████\n\
      ████ ▌█▐█▌ ▌█▌▐▐█▌▐▐▌▐█▌█▐▐█▌▐▐▌▌█  █▐ █▐█▌██▐▌▐▐█▌▐▐▌█▐ ██  █▐▌▌▐█ ▐▐ ████\n\
      ███████████████████████████████████████████████████████████████████████████\n\
      "
  """
  def printable(string, subcode \\ :code128b, height \\ 4, inverse \\ true) do
    hpad = Barcode.Boxify.encode(if(inverse, do: <<255>>, else: <<0>>), newline: false)
    data = encode(string, subcode)
    quiet = if inverse, do: 1, else: 0
    bdata = for <<_::size(1) <- data>>, do: <<quiet::size(1)>>, into: <<>>
    bline = [hpad, Barcode.Boxify.encode(bdata, newline: false), hpad, ?\n]
    line = [hpad, Barcode.Boxify.encode(data, inverse: inverse, newline: false), hpad, ?\n]
    [bline, List.duplicate(line, height), bline]
  end

  @doc """
  Create a bitstring of 1 = dark, 0 = light values in Code 128b. Only a subset of ascii is supported.
  Characters unsupported by Code128b will be replaces with spaces.

      iex> Barcode.Code128.encode("Wikipedia")
      <<210, 29, 26, 26, 97, 40, 105, 79, 44, 132, 38, 134, 146, 195, 201, 99, 43::size(6)>>
  """
  def encode(string, subcode \\ :code128b)
  def encode(string, :code128b), do: encode(string, __MODULE__.Code128B)
  def encode(string, :code128a), do: encode(string, __MODULE__.Code128A)

  def encode(string, module) do
    start = bits(module.value(:start))
    stop = bits(module.value(:stop))

    {data, sum} =
      String.graphemes(string)
      |> Stream.map(&module.value/1)
      |> Stream.with_index(1)
      |> Enum.reduce({start, 1}, fn {v, i}, {acc, sum} ->
        {<<acc::bits, bits(v)::bits>>, rem(sum + i * v, 103)}
      end)

    <<data::bits, bits(sum)::bits, stop::bits, 0b11::size(2)>>
  end

  defmodule Code128A do
    # Specials
    def value(:start), do: 103
    def value(:stop), do: 106
    def value(:function_1), do: 102
    def value(:function_2), do: 97
    def value(:function_3), do: 96
    def value(:function_4), do: 101
    def value(:shift_b), do: 98
    def value(:code_b), do: 100
    def value(:code_c), do: 99

    # ASCII Control char range 00-1F: 0..31 -> 64..95
    def value(<<c>>) when c in 0..31, do: c + 64

    # ASCII char range 20-5F: 32..95 -> 0..63
    def value(<<c>>) when c in 32..95, do: c - 32
  end

  defmodule Code128B do
    # Specials
    def value(:start), do: 104
    def value(:stop), do: 106
    def value(:function_1), do: 102
    def value(:function_2), do: 97
    def value(:function_3), do: 96
    def value(:function_4), do: 100
    def value(:shift_a), do: 98
    def value(:code_a), do: 101
    def value(:code_c), do: 99

    # ASCII char range 20-7F: 32..127 -> 0..95
    def value(<<c>>) when c in 32..127, do: c - 32
  end
end
