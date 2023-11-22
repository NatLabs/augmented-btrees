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

import { BpTree } "../src";
import Utils "../src/internal/Utils";

type Order = Order.Order;

func print_node(node : BpTree.Node<Nat, Nat>) {
    switch (node) {
        case (#branch(n)) {
            Debug.print("branch keys: " # debug_show n.keys);
            Debug.print("branch children: " # debug_show n.children);

        };
        case (#leaf(n)) {
            Debug.print("leaf node: " # debug_show n.kvs);
        };
    };
};

let fuzz = Fuzz.Fuzz();

suite(
    "b-plus-tree",
    func() {

        let limit = 10_000;
        let data = Buffer.Buffer<Nat>(limit);

        for (i in Iter.range(0, limit - 1)) {
            let n = fuzz.nat.randomRange(1, limit * 10);
            data.add(n);
        };

        let unique_iter = Itertools.unique<Nat>(data.vals(), Nat32.fromNat, Nat.equal);
        let random = Itertools.toBuffer<Nat>(unique_iter);
        assert random.size() > 9_000;
        test(
            "insert random",
            func() {
                let bptree = BpTree.newWithOrder<Nat, Nat>(4);
                assert bptree.order == 4;
                Debug.print("random size " # debug_show random.size());
                for (v in random.vals()) {
                    ignore BpTree.insert(bptree, Nat.compare, v, v);
                };

                assert BpTree.size(bptree) == random.size();
                let keys = BpTree.keys(bptree);
                var prev : Nat = Utils.unwrap(keys.next(), "expected key");

                // Debug.print("entries " # debug_show BpTree.toArray(bptree));
                for ((i, curr) in Itertools.enumerate(keys)) {
                    if (prev > curr) {
                        let leaf_node = BpTree.get_leaf_node(bptree, Nat.compare, curr);
                        Debug.print("leaf node:" # BpTree.Leaf.toText(leaf_node, Nat.toText, Nat.toText));
                        Debug.print("mismatch: " # debug_show (prev, curr) # " at index " # debug_show i);
                        assert false;
                    };

                    prev := curr;
                };
            },
        );
        test(
            "delete with insertion order",
            func() {
                let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
                let rand = Iter.toArray(iter);

                let bptree = BpTree.fromEntries(rand.vals(), Nat.compare);
                assert BpTree.size(bptree) == rand.size();

                label _l for ((i, (k, v)) in Itertools.enumerate(rand.vals())) {

                    // Debug.print("deleting " # debug_show k # " at index " # debug_show i);
                    if (?v != BpTree.remove(bptree, Nat.compare, k)) {
                        Debug.print("mismatch: " # debug_show (k, v) # " at index " # debug_show i);
                        assert false;
                    };

                    assert BpTree.size(bptree) == (rand.size() - i - 1 : Nat);
                };

                assert BpTree.size(bptree) == 0;
            },
        );

        test(
            "delete with acsending order",
            func() {
                let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
                let rand = Itertools.toBuffer<(Nat, Nat)>(iter);
                rand.sort(func(a : (Nat, Nat), b : (Nat, Nat)) : Order = Nat.compare(a.0, b.0));
                let bptree = BpTree.fromEntries(rand.vals(), Nat.compare);
                assert BpTree.size(bptree) == rand.size();

                label _l for ((i, (k, v)) in Itertools.enumerate(rand.vals())) {

                    // Debug.print("deleting " # debug_show k # " at index " # debug_show i);
                    if (?v != BpTree.remove(bptree, Nat.compare, k)) {
                        Debug.print("mismatch: " # debug_show (k, v) # " at index " # debug_show i);
                        assert false;
                    };

                    assert BpTree.size(bptree) == (rand.size() - i - 1 : Nat);
                };

                assert BpTree.size(bptree) == 0;
            },
        );
    },
);
