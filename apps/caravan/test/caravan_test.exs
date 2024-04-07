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
        config = Caravan.Worker.new()
        Caravan.Worker.run(config)
      end)
    end)

    client =
      Emulation.spawn(:client, fn ->
        Emulation.send(:server, :test1)
        Emulation.send(:server, :test2)
        Emulation.send(:server, :test3)

        receive do
          {:server, response} -> IO.inspect(response)
        end

        receive do
          {:server, response} -> IO.inspect(response)
        end

        receive do
          {:server, response} -> IO.inspect(response)
        end
      end)

    handle = Process.monitor(client)

    receive do
      {:DOWN, ^handle, _, _, _} -> true
    after
      5_000 -> assert false
    end
  after
    Emulation.terminate()
  end
end
