defmodule Flock.CRDTTest do
  use ExUnit.Case

  alias Flock.CRDT

  setup_all do
    {:ok, crdt: CRDT.new()}
  end

  test "create CRDT" do
    assert CRDT.new() == %CRDT{added: [], removed: []}
  end

  test "Add element to CRDT" do
    crdt = CRDT.new()
    assert :a in (CRDT.add(crdt, :a) |> CRDT.to_list())
  end

  test "fail add existing element to CRDT", %{crdt: crdt} do
    crdt = CRDT.add(crdt, :a)

    assert CRDT.add(crdt, :a) == {:error, :already_exists}
  end

  test "remove element", %{crdt: crdt} do
    crdt = CRDT.add(crdt, :a)

    assert :a not in (CRDT.remove(crdt, :a) |> CRDT.to_list())
  end

  test "fail remove non existent element", %{crdt: crdt} do
    assert CRDT.remove(crdt, :a) == {:error, :not_found}
  end

  test "join two CRDTs", %{crdt: crdt} do
    crdt1 = crdt |> CRDT.add(:a) |> CRDT.add(:b)
    crdt2 = crdt |> CRDT.add(:c) |> CRDT.add(:b) |> CRDT.remove(:b)
    joined_crdt = CRDT.join(crdt1, crdt2)

    assert :a in CRDT.to_list(joined_crdt)
    assert :b not in CRDT.to_list(joined_crdt)
    assert :c in CRDT.to_list(joined_crdt)
  end

  test "return a list of current elements in CRDT" do
    crdt = %CRDT{added: [:b, :a, :c], removed: [:b]}

    assert CRDT.to_list(crdt) == [:a, :c]
  end
end
