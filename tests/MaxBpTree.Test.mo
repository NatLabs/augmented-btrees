import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import TrieSet "mo:base/TrieSet";

import { test; suite } "mo:test";
import Fuzz "mo:fuzz";
import Itertools "mo:itertools/Iter";

import Utils "../src/internal/Utils";
import { MaxBpTree } "../src";

type Order = Order.Order;

let fuzz = Fuzz.fromSeed(0x7f3a3e7e);

let limit = 10_000;
let data = Buffer.Buffer<Nat>(limit);

for (i in Iter.range(0, limit - 1)) {
    let n = fuzz.nat.randomRange(1, limit * 10);
    data.add(n);
};

let unique_iter = Itertools.unique<Nat>(data.vals(), Nat32.fromNat, Nat.equal);
let random = Itertools.toBuffer<Nat>(unique_iter);
// assert random.size() * 100 > (limit) * 95;

func max_bp_tree_test(order : Nat, random : Buffer.Buffer<Nat>) {
    test(
        "insert random",
        func() {
            let max_bp_tree = MaxBpTree.new<Nat, Nat>(?order);
            assert max_bp_tree.order == order;

            label for_loop for ((i, v) in Itertools.enumerate(random.vals())) {
                ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, v, v);

                let subtree_size = switch (max_bp_tree.root) {
                    case (#branch(node)) { node.subtree_size };
                    case (#leaf(node)) { node.count };
                };

                assert subtree_size == i + 1;
            };

            assert MaxBpTree.size(max_bp_tree) == random.size();

            let root_subtree_size = switch (max_bp_tree.root) {
                case (#leaf(node)) node.count;
                case (#branch(node)) node.subtree_size;
            };

            assert root_subtree_size == random.size();

            let keys = MaxBpTree.keys(max_bp_tree);
            var prev : Nat = Utils.unwrap(keys.next(), "expected key");

            // Debug.print("entries " # debug_show MaxBpTree.toArray(max_bp_tree));
            for ((i, curr) in Itertools.enumerate(keys)) {
                if (prev > curr) {
                    Debug.print("mismatch: " # debug_show (prev, curr) # " at index " # debug_show i);
                    assert false;
                };

                prev := curr;
            };
        },
    );

    test("retrieve max value", func (){
        let max_bp_tree = MaxBpTree.new<Nat, Nat>(?order);
        assert max_bp_tree.order == order;

        let init_val = random.get(0);
        ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, init_val, init_val);
        var max = (init_val, init_val);

        assert MaxBpTree.maxValue(max_bp_tree) == ?max;

        label for_loop for ((i, v) in Itertools.enumerate(Itertools.skip(random.vals(), 1))) {

            ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, v, v);

            if (v > max.0) {
                max := (v, v);
            };

            assert MaxBpTree.maxValue(max_bp_tree) == ?max;
        };
    });
};

for (order in [4, 32].vals()) {
    suite(
        "Max B+Tree Test: order " # debug_show order,
        func() = max_bp_tree_test(order, random),
    );
};
