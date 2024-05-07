defmodule CaravanTest do
  use ExUnit.Case
  doctest Caravan

  test "Caravan responds to commands" do
    Emulation.init()

    nodes = [:a, :b, :c]
    config = Caravan.new_configuration(nodes)

    Emulation.spawn(:server, fn -> Caravan.run(config) end)

    nodes
    |> Enum.map(fn x ->
      Emulation.spawn(x, fn ->
        config = Caravan.Worker.new()
        Caravan.Worker.run(config)
      end)
    end)

    client =
      Emulation.spawn(:client, fn ->
        Emulation.send(:server, Caravan.Task.new(:double, 2))
        Emulation.send(:server, Caravan.Task.new(:double, 3))
        Emulation.send(:server, Caravan.Task.new(:double, 4))

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

  test "Caravan responds to 1000 commands" do
    Emulation.init()

    nodes = [:a, :b, :c]
    config = Caravan.new_configuration(nodes)

    Emulation.spawn(:server, fn -> Caravan.run(config) end)

    nodes
    |> Enum.map(fn x ->
      Emulation.spawn(x, fn ->
        config = Caravan.Worker.new()
        Caravan.Worker.run(config)
      end)
    end)

    client =
      Emulation.spawn(:client, fn ->
        for x <- 1..1000 do
          Emulation.send(:server, Caravan.Task.new(:double, x))
        end

        for _ <- 1..1000 do
          receive do
            {:server, _} -> nil
          end
        end
      end)

    handle = Process.monitor(client)

    receive do
      {:DOWN, ^handle, _, _, _} -> true
    after
      30_000 -> assert false
    end
  after
    Emulation.terminate()
  end
end
