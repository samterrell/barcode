defmodule Barcode.Boxify do
  @moduledoc """
  Convert bitstings to box art.
  """
  require Record
  Record.defrecordp(:config, wide: false, lines_per_char: 3, newline: "\n", inverse: false)

  @doc """
  Convert bitstings to box art.

  - `data` is either an enum of bitstrings for two dimensional data or a single bitstring for one dimensional data
  - `opts` options for encoding.
    - `wide` - true/false, produce full char width pixels, or use half blocks
    - `lines_per_char` - 2/3, use ascii 2x2 chars, or unicode 3 block tall chars
    - `newline` - true/false/io, terminate each line with given char, \\n, or nothing
    - `inverse` - inverts block chars ex: `▘` <-> `▟`
  """
  def encode(data, opts \\ [])

  def encode(lines, opts) do
    wide = Keyword.get(opts, :wide, false)
    unless wide in [true, false], do: raise("Invalid value #{inspect(wide)} for option :wide.")
    lines_per_char = Keyword.get(opts, :lines_per_char, 3)

    unless lines_per_char in 2..3,
      do: raise("Invalid value #{inspect(lines_per_char)} for option :lines_per_char.")

    newline =
      case Keyword.get(opts, :newline, "\n") do
        nil -> ""
        false -> ""
        true -> "\n"
        bin when is_binary(bin) -> bin
        other -> raise "Invalid value #{inspect(other)} for option :newline."
      end

    inverse =
      case Keyword.get(opts, :inverse, false) do
        false -> false
        true -> true
        other -> raise "Invalid value #{inspect(other)} for option :inverse."
      end

    encode_lines(
      lines,
      config(wide: wide, lines_per_char: lines_per_char, newline: newline, inverse: inverse)
    )
  end

  # 1-dimensional
  defp encode_lines(line, config) when is_bitstring(line) do
    bitstream(line, config)
    |> Enum.map(&encode_char([&1, &1], config))
  end

  # 2-dimensional
  defp encode_lines(lines, config = config(lines_per_char: lpc)) do
    Stream.chunk_every(lines, lpc, lpc, Stream.repeatedly(fn -> nil end))
    |> Enum.map(&encode_line(&1, config))
  end

  defp encode_line(bits, config) do
    bits
    |> Enum.map(&bitstream(&1, config))
    |> Enum.zip_with(&encode_char(&1, config))
  end

  defp bitstream(nil, _), do: Stream.repeatedly(fn -> 0 end)
  defp bitstream(binary, config), do: Stream.unfold(binary, &next_bits(&1, config))

  defp next_bits(<<>>, _), do: {:newline, nil}
  defp next_bits(nil, _), do: nil
  defp next_bits(<<v::size(1), rest::bits>>, config(wide: true)), do: {v * 3, rest}
  defp next_bits(<<v::size(2), rest::bits>>, config(wide: false)), do: {v, rest}
  defp next_bits(<<v::size(1)>>, config(wide: false)), do: {v * 2, <<>>}

  # special
  defp encode_char(:newline, config), do: config(config, :newline)
  defp encode_char([:newline | _], config), do: config(config, :newline)

  defp encode_char(data, config = config(inverse: true)) do
    Enum.map(data, &(3 - &1))
    |> encode_char(config(config, inverse: false))
  end

  # 2x3
  defp encode_char([0, 0, 0], _), do: " "
  defp encode_char([0, 0, 1], _), do: "🬞"
  defp encode_char([0, 0, 2], _), do: "🬏"
  defp encode_char([0, 0, 3], _), do: "🬭"
  defp encode_char([0, 1, 0], _), do: "🬇"
  defp encode_char([0, 1, 1], _), do: "🬦"
  defp encode_char([0, 1, 2], _), do: "🬖"
  defp encode_char([0, 1, 3], _), do: "🬵"
  defp encode_char([0, 2, 0], _), do: "🬃"
  defp encode_char([0, 2, 1], _), do: "🬢"
  defp encode_char([0, 2, 2], _), do: "🬓"
  defp encode_char([0, 2, 3], _), do: "🬱"
  defp encode_char([0, 3, 0], _), do: "🬋"
  defp encode_char([0, 3, 1], _), do: "🬩"
  defp encode_char([0, 3, 2], _), do: "🬚"
  defp encode_char([0, 3, 3], _), do: "🬹"
  defp encode_char([1, 0, 0], _), do: "🬁"
  defp encode_char([1, 0, 1], _), do: "🬠"
  defp encode_char([1, 0, 2], _), do: "🬑"
  defp encode_char([1, 0, 3], _), do: "🬯"
  defp encode_char([1, 1, 0], _), do: "🬉"
  defp encode_char([1, 1, 1], _), do: "▐"
  defp encode_char([1, 1, 2], _), do: "🬘"
  defp encode_char([1, 1, 3], _), do: "🬷"
  defp encode_char([1, 2, 0], _), do: "🬅"
  defp encode_char([1, 2, 1], _), do: "🬤"
  defp encode_char([1, 2, 2], _), do: "🬔"
  defp encode_char([1, 2, 3], _), do: "🬳"
  defp encode_char([1, 3, 0], _), do: "🬍"
  defp encode_char([1, 3, 1], _), do: "🬫"
  defp encode_char([1, 3, 2], _), do: "🬜"
  defp encode_char([1, 3, 3], _), do: "🬻"
  defp encode_char([2, 0, 0], _), do: "🬀"
  defp encode_char([2, 0, 1], _), do: "🬟"
  defp encode_char([2, 0, 2], _), do: "🬐"
  defp encode_char([2, 0, 3], _), do: "🬮"
  defp encode_char([2, 1, 0], _), do: "🬈"
  defp encode_char([2, 1, 1], _), do: "🬧"
  defp encode_char([2, 1, 2], _), do: "🬗"
  defp encode_char([2, 1, 3], _), do: "🬶"
  defp encode_char([2, 2, 0], _), do: "🬄"
  defp encode_char([2, 2, 1], _), do: "🬣"
  defp encode_char([2, 2, 2], _), do: "▌"
  defp encode_char([2, 2, 3], _), do: "🬲"
  defp encode_char([2, 3, 0], _), do: "🬌"
  defp encode_char([2, 3, 1], _), do: "🬪"
  defp encode_char([2, 3, 2], _), do: "🬛"
  defp encode_char([2, 3, 3], _), do: "🬺"
  defp encode_char([3, 0, 0], _), do: "🬂"
  defp encode_char([3, 0, 1], _), do: "🬡"
  defp encode_char([3, 0, 2], _), do: "🬒"
  defp encode_char([3, 0, 3], _), do: "🬰"
  defp encode_char([3, 1, 0], _), do: "🬊"
  defp encode_char([3, 1, 1], _), do: "🬨"
  defp encode_char([3, 1, 2], _), do: "🬙"
  defp encode_char([3, 1, 3], _), do: "🬸"
  defp encode_char([3, 2, 0], _), do: "🬆"
  defp encode_char([3, 2, 1], _), do: "🬥"
  defp encode_char([3, 2, 2], _), do: "🬕"
  defp encode_char([3, 2, 3], _), do: "🬴"
  defp encode_char([3, 3, 0], _), do: "🬎"
  defp encode_char([3, 3, 1], _), do: "🬬"
  defp encode_char([3, 3, 2], _), do: "🬝"
  defp encode_char([3, 3, 3], _), do: "█"

  # 2x2
  defp encode_char([0, 0], _), do: " "
  defp encode_char([0, 1], _), do: "▗"
  defp encode_char([0, 2], _), do: "▖"
  defp encode_char([0, 3], _), do: "▄"
  defp encode_char([1, 0], _), do: "▝"
  defp encode_char([1, 1], _), do: "▐"
  defp encode_char([1, 2], _), do: "▞"
  defp encode_char([1, 3], _), do: "▟"
  defp encode_char([2, 0], _), do: "▘"
  defp encode_char([2, 1], _), do: "▚"
  defp encode_char([2, 2], _), do: "▌"
  defp encode_char([2, 3], _), do: "▙"
  defp encode_char([3, 0], _), do: "▀"
  defp encode_char([3, 1], _), do: "▜"
  defp encode_char([3, 2], _), do: "▛"
  defp encode_char([3, 3], _), do: "█"
end
