
import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import { test; suite } "mo:test";

import { BpTree } "../src";

suite(
    "b-plus-tree",
    func() {
        test(
            "insert",
            func() {
                let bptree = BpTree.new<Nat, Nat>();

                for (i in Iter.range(0, 512 - 1)){
                    ignore BpTree.insert<Nat, Nat>(bptree, Nat.compare, i, i);
                };

                assert bptree.size == 512;

                let entries = BpTree.toArray(bptree);
                let valid_entries = Array.tabulate<(Nat, Nat)>(512, func(i: Nat): (Nat, Nat) = (i, i));

                assert entries.size() == 512;
                assert entries == valid_entries;
            },
        );
    },
);


suite(
    "Function Tests",
    func() {
        test(
            "binary search",
            func() {
                let arr = [var ?1, ?3, ?5, ?7, null];
                var count = 4;

                assert 0 == BpTree.binary_search<Nat>(arr, Nat.compare, 1, count);
                assert 1 == BpTree.binary_search<Nat>(arr, Nat.compare, 3, count);
                assert 2 == BpTree.binary_search<Nat>(arr, Nat.compare, 5, count);
                assert 3 == BpTree.binary_search<Nat>(arr, Nat.compare, 7, count);

                assert -1 == BpTree.binary_search<Nat>(arr, Nat.compare, 0, count);
                assert -2 == BpTree.binary_search<Nat>(arr, Nat.compare, 2, count);
                assert -3 == BpTree.binary_search<Nat>(arr, Nat.compare, 4, count);
                assert -4 == BpTree.binary_search<Nat>(arr, Nat.compare, 6, count);
                assert -5 == BpTree.binary_search<Nat>(arr, Nat.compare, 8, count);

                arr[4] := ?9;
                count := 5;

                assert 4 == BpTree.binary_search<Nat>(arr, Nat.compare, 9, count);
                assert -5 == BpTree.binary_search<Nat>(arr, Nat.compare, 8, count);
                assert -6 == BpTree.binary_search<Nat>(arr, Nat.compare, 10, count);

                arr[4] := null;
                arr[3] := null;
                arr[2] := null;
                arr[1] := null;
                count := 1;

                assert 0 == BpTree.binary_search<Nat>(arr, Nat.compare, 1, count);
                assert -1 == BpTree.binary_search<Nat>(arr, Nat.compare,0, count);
                assert -2 == BpTree.binary_search<Nat>(arr, Nat.compare, 10, count);

            },
        );
    },
);
