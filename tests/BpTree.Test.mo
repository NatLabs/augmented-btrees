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
        assert random.size() > 9_500;
        
        test(
            "insert random",
            func() {
                let bptree = BpTree.newWithOrder<Nat, Nat>(4);
                assert bptree.order == 4;
                // Debug.print("random size " # debug_show random.size());
                for (v in random.vals()) {
                    ignore BpTree.insert(bptree, Nat.compare, v, v);
                };

                assert BpTree.size(bptree) == random.size();
                let keys = BpTree.keys(bptree);
                var prev : Nat = Utils.unwrap(keys.next(), "expected key");
                Debug.print("prev " # debug_show prev);

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

        test("get", func(){
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Iter.toArray(iter);

            let bptree = BpTree.fromEntries(rand.vals(), Nat.compare);

            for ((k, v) in rand.vals()) {
                let retrieved = BpTree.get(bptree, Nat.compare, k);
                if (?v != retrieved) {
                    Debug.print("mismatch: " # debug_show (?v, retrieved, ?v == retrieved));
                    assert false;
                };
            };
        });

        test(
            "delete with ascending order",
            func() {
                let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
                let rand = Itertools.toBuffer<(Nat, Nat)>(iter);
                rand.sort(func(a : (Nat, Nat), b : (Nat, Nat)) : Order = Nat.compare(a.0, b.0));
                let bptree = BpTree.fromEntries(rand.vals(), Nat.compare);
                assert BpTree.size(bptree) == rand.size();

                label _l for ((i, (k, v)) in Itertools.enumerate(rand.vals())) {

                    // Debug.print("deleting " # debug_show k # " at index " # debug_show i);
                    let removed = BpTree.remove(bptree, Nat.compare, k);
                    if (?v != removed) {
                        Debug.print("mismatch: " # debug_show (?v, removed, ?v == removed) # " at index " # debug_show i);
                        assert false;
                    };

                    assert BpTree.size(bptree) == (rand.size() - i - 1 : Nat);
                };

                assert BpTree.size(bptree) == 0;
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
                    let removed = BpTree.remove(bptree, Nat.compare, k);
                    if (?v != removed) {
                        Debug.print("mismatch: " # debug_show (?v, removed, ?v == removed) # " at index " # debug_show i);
                        Debug.print("keys " # debug_show BpTree.toNodeKeys(bptree));
                        Debug.print("leafs " # debug_show BpTree.toLeafNodes(bptree));
                        assert false;
                    };

                    // Debug.print("keys " # debug_show BpTree.toNodeKeys(bptree));
                    // Debug.print("leafs " # debug_show BpTree.toLeafNodes(bptree));

                    assert BpTree.size(bptree) == (rand.size() - i - 1 : Nat);
                };

                assert BpTree.size(bptree) == 0;
            },
        );

        test("entries.rev()", func(){
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(Itertools.take(iter, 1000));

            let bptree = BpTree.fromEntries(rand.vals(), Nat.compare);

            assert BpTree.size(bptree) == rand.size();

            rand.sort(Utils.tuple_cmp(Nat.compare));
            Buffer.reverse(rand);

            for ((i, (k, v)) in Itertools.enumerate(BpTree.entries(bptree).rev())) {
                let expected = rand.get(i).1;

                if (v != expected) {
                    Debug.print("mismatch: (" # debug_show i # ") ->" # debug_show (v, expected, v == expected));
                    Debug.print("revEntries " # debug_show Iter.toArray(BpTree.entries(bptree).rev()));
                    assert false;
                };
            };

            while (rand.size() > 1) {
                let index = fuzz.nat.randomRange(0, rand.size() - 1);
                let (k, v) = rand.remove(index);
                assert ?v == BpTree.remove(bptree, Nat.compare, k);

                assert Buffer.toArray(rand) == Iter.toArray(BpTree.entries(bptree).rev());
            };

            assert BpTree.entries(bptree).next() == ?rand.get(0);
        });
    },
);
