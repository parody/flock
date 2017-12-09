defmodule Flock.CRDTTest do
  use ExUnit.Case

  alias Flock.CRDT

  setup_all do
    {:ok, crdt: CRDT.new()}
  end

  test "create CRDT" do
    assert CRDT.new() == %CRDT{added: [], removed: []}
  end

  test "add element to CRDT", %{crdt: crdt} do
    assert CRDT.add(crdt, :a) == %CRDT{added: [:a], removed: []}
  end

  test "fail add existing element to CRDT", %{crdt: crdt} do
    crdt = CRDT.add(crdt, :a)

    assert CRDT.add(crdt, :a) == {:error, :already_exists}
  end

  test "remove element", %{crdt: crdt} do
    crdt = CRDT.add(crdt, :a)

    assert CRDT.remove(crdt, :a) == %CRDT{added: [], removed: [:a]}
  end

  test "fail remove non existent element", %{crdt: crdt} do
    assert CRDT.remove(crdt, :a) == {:error, :not_found}
  end

  test "join two CRDTs", %{crdt: crdt} do
    crdt1 = crdt |> CRDT.add(:a) |> CRDT.add(:b)
    crdt2 = crdt |> CRDT.add(:c) |> CRDT.add(:b) |> CRDT.remove(:b)

    assert CRDT.join(crdt1, crdt2) == %CRDT{added: [:a, :c], removed: [:b]}
  end

  test "return a list of current elements in CRDT" do
    crdt = %CRDT{added: [:b, :a, :c], removed: [:b]}

    assert CRDT.to_list(crdt) == [:a, :c]
  end
end
