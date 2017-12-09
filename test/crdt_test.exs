defmodule Flock.CRDTTest do
  use ExUnit.Case

  alias Flock.CRDT

  test "Create CRDT" do
    assert CRDT.new() == %CRDT{added: [], removed: []}
  end

  test "Add element to CRDT" do
    crdt = CRDT.new()
    assert CRDT.add(crdt, :a) == %CRDT{added: [:a], removed: []}
  end

  test "Fail add existing element to CRDT" do
    crdt = CRDT.new() |> CRDT.add(:a)
    assert CRDT.add(crdt, :a) == {:error, "Element already exists."}
  end

  test "Remove element " do
    crdt = CRDT.new() |> CRDT.add(:a)
    assert CRDT.remove(crdt, :a) == %CRDT{added: [], removed: [:a]}
  end

  test "Fail remove non existent element " do
    crdt = CRDT.new()
    assert CRDT.remove(crdt, :a) == {:error, "Element does not exists."}
  end

  test "Join two CRDTs" do
    crdt1 = CRDT.new() |> CRDT.add(:a) |> CRDT.add(:b)
    crdt2 = CRDT.new() |> CRDT.add(:c) |> CRDT.add(:b) |> CRDT.remove(:b)
    assert CRDT.join(crdt1, crdt2) == %CRDT{added: [:a, :c], removed: [:b]}
  end

  test "Get a list of current elements in CRDT" do
    crdt = %CRDT{added: [:b, :a, :c], removed: [:b]}
    assert CRDT.to_list(crdt) == [:a, :c]
  end
end
