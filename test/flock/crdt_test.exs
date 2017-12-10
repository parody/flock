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

  test "Get element by" do
    crdt = CRDT.new()

    assert {:error, :not_found} = crdt |> CRDT.get_by(fn e -> e == :a end)

    assert {:ok, :b} =
      CRDT.add(crdt, :a)
      |> CRDT.add(:b)
      |> CRDT.add(:c)
      |> CRDT.get_by(fn e -> e == :b end)
  end

  test "fail add existing element to CRDT", %{crdt: crdt} do
    crdt = CRDT.add(crdt, :a)

    assert CRDT.add(crdt, :a) == {:error, :already_exists}
  end

  test "remove element", %{crdt: crdt} do
    crdt = CRDT.add(crdt, :a)

    assert :a not in (CRDT.remove(crdt, :a) |> CRDT.to_list())
  end

  test "remove element by", %{crdt: crdt} do
    crdt = CRDT.add(crdt, :a)

    assert :a not in (CRDT.remove_by(crdt, fn e -> e == :a end) |> CRDT.to_list())
  end

  test "Add a previously removed element", %{crdt: crdt} do
    crdt =
      crdt
      |> CRDT.add(:a)
      |> CRDT.remove(:a)
      |> CRDT.add(:a)

    assert :a in CRDT.to_list(crdt)
  end

  test "fail remove non existent element", %{crdt: crdt} do
    assert CRDT.remove(crdt, :a) == {:error, :not_found}
  end

  test "fail remove by non existent element", %{crdt: crdt} do
    assert CRDT.remove_by(crdt, fn e -> e == :a end) == {:error, :not_found}
  end

  test "join two CRDTs", %{crdt: crdt} do
    crdt1 = crdt |> CRDT.add(:a) |> CRDT.add(:b)
    crdt2 = crdt |> CRDT.add(:c) |> CRDT.add(:b) |> CRDT.remove(:b)

    joined_crdt = CRDT.join(crdt1, crdt2)

    assert :a in CRDT.to_list(joined_crdt)
    assert :b in CRDT.to_list(joined_crdt)
    assert :c in CRDT.to_list(joined_crdt)

    removed_b = CRDT.remove(joined_crdt, :b)

    assert :a in CRDT.to_list(removed_b)
    assert :b not in CRDT.to_list(removed_b)
    assert :c in CRDT.to_list(removed_b)
  end
end
