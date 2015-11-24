# Barcode

Make some barcodes...
```elixir
Barcode.Code128b.printable("Wikipedia")
|> IO.puts
```
![Example](example.png?raw=true)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add barcode to your list of dependencies in `mix.exs`:

        def deps do
          [{:barcode, "~> 0.0.1"}]
        end

  2. Ensure barcode is started before your application:

        def application do
          [applications: [:barcode]]
        end
