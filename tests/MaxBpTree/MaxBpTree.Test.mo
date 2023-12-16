import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import { test; suite } "mo:test";
import Itertools "mo:itertools/Iter";

import { MaxBpTree } "../../src/";

suite(
    "Max B+Tree Tests",
    func() {
        test("test", func() {
            let map = MaxBpTree.new<Nat, Nat>(?32);
            ignore MaxBpTree.insert(map, Nat.compare, Nat.compare, 1, 1);
            Debug.print(debug_show MaxBpTree.get(map, Nat.compare, 1));
        });
    }
);