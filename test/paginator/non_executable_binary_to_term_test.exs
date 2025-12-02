defmodule Paginator.NonExecutableBinaryToTermTest do
  use ExUnit.Case, async: true

  alias Paginator.NonExecutableBinaryToTerm

  describe "decode/2" do
    test "decodes safe terms correctly" do
      value = %{1 => {:foo, ["bar", 2.0, [self() | make_ref()], <<0::4>>]}}
      binary = :erlang.term_to_binary(value)
      assert NonExecutableBinaryToTerm.decode(binary) == value
    end

    test "decodes complex nested structures" do
      value = %{
        atoms: [:atom1, :atom2],
        strings: ["string1", "string2"],
        numbers: [1, 2, 3.14],
        tuples: {:a, :b, :c},
        maps: %{nested: %{key: "value"}},
        lists: [[1, 2], [3, 4]]
      }

      binary = :erlang.term_to_binary(value)
      assert NonExecutableBinaryToTerm.decode(binary) == value
    end

    test "decodes with :safe option" do
      value = %{key: "value", number: 42}
      binary = :erlang.term_to_binary(value)
      assert NonExecutableBinaryToTerm.decode(binary, [:safe]) == value
    end

    test "raises ArgumentError for executable terms (anonymous functions)" do
      binary = :erlang.term_to_binary(%{1 => {:foo, [fn -> :bar end]}})

      assert_raise ArgumentError, ~r/cannot deserialize/, fn ->
        NonExecutableBinaryToTerm.decode(binary)
      end
    end

    test "raises ArgumentError with :safe option for new atoms" do
      # This binary contains an atom that might not exist
      binary = <<131, 100, 0, 7, 103, 114, 105, 102, 102, 105, 110>>

      assert_raise ArgumentError, fn ->
        NonExecutableBinaryToTerm.decode(binary, [:safe])
      end
    end

    test "handles empty collections" do
      assert NonExecutableBinaryToTerm.decode(:erlang.term_to_binary([])) == []
      assert NonExecutableBinaryToTerm.decode(:erlang.term_to_binary({})) == {}
      assert NonExecutableBinaryToTerm.decode(:erlang.term_to_binary(%{})) == %{}
    end

    test "handles pid and reference types" do
      pid = self()
      ref = make_ref()
      value = %{pid: pid, ref: ref}
      binary = :erlang.term_to_binary(value)
      assert NonExecutableBinaryToTerm.decode(binary) == value
    end

    test "handles bitstrings" do
      value = %{bitstring: <<1, 2, 3>>, aligned: <<0::4>>}
      binary = :erlang.term_to_binary(value)
      assert NonExecutableBinaryToTerm.decode(binary) == value
    end

    test "handles improper lists" do
      value = [1, 2 | 3]
      binary = :erlang.term_to_binary(value)
      assert NonExecutableBinaryToTerm.decode(binary) == value
    end
  end
end
