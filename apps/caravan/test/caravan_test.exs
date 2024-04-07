defmodule CaravanTest do
  use ExUnit.Case
  doctest Caravan

  test "Caravan responds to commands" do
    Emulation.init()

    nodes = [:a, :b, :c]
    config = Caravan.new_configuration(nodes)

    server = Emulation.spawn(:server, fn -> Caravan.run(config) end)

    nodes
    |> Enum.map(fn x ->
      Emulation.spawn(x, fn ->
        config = Caravan.Worker.new(x)
        Caravan.Worker.run(config)
      end)
    end)

    client =
      Emulation.spawn(:client, fn ->
        IO.puts("Sending server a test message")
        Emulation.send(:server, :test)
      end)

    receive do
      _ -> true
    after
      5_000 -> assert false
    end
  end
end
