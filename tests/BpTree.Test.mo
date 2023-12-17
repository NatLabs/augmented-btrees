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

import {BpTree} "../src";
import Utils "../src/internal/Utils";

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

func bp_tree_test(order : Nat, random : Buffer.Buffer<Nat>) {

    test(
        "insert random",
        func() {
            let bptree = BpTree.new<Nat, Nat>(?4);
            assert bptree.order == 4;
            // Debug.print("random size " # debug_show random.size());
            label for_loop for ((i, v) in Itertools.enumerate(random.vals())) {
                ignore BpTree.insert(bptree, Nat.compare, v, v);
                // Debug.print("keys " # debug_show BpTree.toNodeKeys(bptree));
                // Debug.print("leafs " # debug_show BpTree.toLeafNodes(bptree));

                let subtree_size = switch (bptree.root) {
                    case (#branch(node)) { node.subtree_size };
                    case (#leaf(node)) { node.count };
                };

                assert subtree_size == i + 1;
            };

            assert BpTree.size(bptree) == random.size();
            // validate root subtree_size
            let root_subtree_size = switch (bptree.root) {
                case (#leaf(node)) node.count;
                case (#branch(node)) node.subtree_size;
            };

            assert root_subtree_size == random.size();

            let keys = BpTree.keys(bptree);
            var prev : Nat = Utils.unwrap(keys.next(), "expected key");

            // Debug.print("entries " # debug_show BpTree.toArray(bptree));
            for ((i, curr) in Itertools.enumerate(keys)) {
                if (prev > curr) {
                    Debug.print("mismatch: " # debug_show (prev, curr) # " at index " # debug_show i);
                    assert false;
                };

                prev := curr;
            };
        },
    );

    test(
        "get",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Iter.toArray(iter);

            let bptree = BpTree.fromEntries<Nat, Nat>(?4, rand.vals(), Nat.compare);

            for ((k, v) in rand.vals()) {
                let retrieved = BpTree.get(bptree, Nat.compare, k);
                if (?v != retrieved) {
                    Debug.print("mismatch: " # debug_show (?v, retrieved, ?v == retrieved));
                    assert false;
                };
            };
        },
    );

    test(
        "delete with ascending order",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(iter);
            rand.sort(func(a : (Nat, Nat), b : (Nat, Nat)) : Order = Nat.compare(a.0, b.0));

            let bptree = BpTree.fromEntries<Nat, Nat>(?4, rand.vals(), Nat.compare);
            assert BpTree.size(bptree) == rand.size();

            label _l for ((i, (k, v)) in Itertools.enumerate(rand.vals())) {

                // Debug.print("deleting " # debug_show k # " at index " # debug_show i);
                let removed = BpTree.remove(bptree, Nat.compare, k);
                if (?v != removed) {
                    Debug.print("mismatch: " # debug_show (?v, removed, ?v == removed) # " at index " # debug_show i);
                    assert false;
                };

                assert BpTree.size(bptree) == (rand.size() - i - 1 : Nat);

                let root_subtree_size = switch (bptree.root) {
                    case (#branch(node)) { node.subtree_size };
                    case (#leaf(node)) { node.count };
                };

                assert root_subtree_size == (rand.size() - i - 1 : Nat);
            };

            assert BpTree.size(bptree) == 0;
        },
    );

    test(
        "delete with descending order",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(iter);
            rand.sort(func(a : (Nat, Nat), b : (Nat, Nat)) : Order = Nat.compare(b.0, a.0));
            let bptree = BpTree.fromEntries<Nat, Nat>(?4, rand.vals(), Nat.compare);
            assert BpTree.size(bptree) == rand.size();

            label _l for ((i, (k, v)) in Itertools.enumerate(rand.vals())) {

                // Debug.print("deleting " # debug_show k # " at index " # debug_show i);
                let removed = BpTree.remove(bptree, Nat.compare, k);
                if (?v != removed) {
                    Debug.print("mismatch: " # debug_show (?v, removed, ?v == removed) # " at index " # debug_show i);
                    assert false;
                };

                assert BpTree.size(bptree) == (rand.size() - i - 1 : Nat);

                let root_subtree_size = switch (bptree.root) {
                    case (#branch(node)) { node.subtree_size };
                    case (#leaf(node)) { node.count };
                };

                assert root_subtree_size == (rand.size() - i - 1 : Nat);
            };

            assert BpTree.size(bptree) == 0;
        },
    );

    test(
        "delete with insertion order",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Iter.toArray(iter);

            let bptree = BpTree.fromEntries<Nat, Nat>(?4, rand.vals(), Nat.compare);
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

    test(
        "entries.rev()",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(Itertools.take(iter, 1000));

            let bptree = BpTree.fromEntries<Nat, Nat>(?4, rand.vals(), Nat.compare);

            assert BpTree.size(bptree) == rand.size();

            rand.sort(Utils.tuple_cmp(Nat.compare));
            Buffer.reverse(rand);

            let entries = BpTree.entries(bptree);
            for ((i, (k, v)) in Itertools.enumerate(entries.rev())) {
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
        },
    );

    test(
        "getRank",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(Itertools.take(iter, 1000));

            let bptree = BpTree.fromEntries<Nat, Nat>(?4, rand.vals(), Nat.compare);

            rand.sort(Utils.tuple_cmp(Nat.compare));

            for (i in Itertools.range(0, rand.size())) {
                let key = rand.get(i).0;
                let rank = BpTree.getRank(bptree, Nat.compare, key);

                if (not (rank == i)) {
                    Debug.print("mismatch for key:" # debug_show key);
                    Debug.print("expected != actual:" # debug_show (i, rank));
                    assert false;
                };
            };
        },
    );

    test(
        "getByRank",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(Itertools.take(iter, 1000));

            let bptree = BpTree.fromEntries<Nat, Nat>(?4, rand.vals(), Nat.compare);

            rand.sort(Utils.tuple_cmp(Nat.compare));

            for (i in Itertools.range(0, rand.size())) {
                let expected = rand.get(i);
                let received = BpTree.getByRank(bptree, i);

                if (not (expected == received)) {
                    Debug.print("mismatch at rank:" # debug_show i);
                    Debug.print("expected != received: " # debug_show (expected, received));
                    assert false;
                };
            };
        },
    );

    test(
        "scan",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let _rand = Iter.toArray<(Nat, Nat)>(Itertools.take(iter, 100));

            let bptree = BpTree.fromEntries<Nat, Nat>(?4, _rand.vals(), Nat.compare);
            let rand = Array.sort<(Nat, Nat)>(_rand, Utils.tuple_cmp(Nat.compare));

            for (i in Itertools.range(0, BpTree.size(bptree))) {

                for (j in Itertools.range(i + 1, BpTree.size(bptree))) {
                    let start_key = rand[i].0;
                    let end_key = rand[j].0;

                    if (
                        not Itertools.equal<(Nat, Nat)>(
                            BpTree.scan(bptree, Nat.compare, start_key, end_key),
                            Itertools.fromArraySlice(rand, i, j + 1),
                            func(a : (Nat, Nat), b : (Nat, Nat)) : Bool = a == b,
                        )
                    ) {
                        Debug.print("mismatch: " # debug_show (i, j));
                        Debug.print("scan " # debug_show Iter.toArray(BpTree.scan(bptree, Nat.compare, start_key, end_key)));
                        Debug.print("expected " # debug_show Iter.toArray(Itertools.fromArraySlice(rand, i, j + 1)));
                        assert false;
                    };
                };
            };
        },
    );

    test(
        "range",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let _rand = Iter.toArray<(Nat, Nat)>(Itertools.take(iter, 100));

            let bptree = BpTree.fromEntries<Nat, Nat>(?4, _rand.vals(), Nat.compare);
            let rand = Array.sort<(Nat, Nat)>(_rand, Utils.tuple_cmp(Nat.compare));

            for (i in Itertools.range(0, BpTree.size(bptree))) {

                for (j in Itertools.range(i + 1, BpTree.size(bptree))) {

                    if (
                        not Itertools.equal<(Nat, Nat)>(
                            BpTree.range(bptree, i, j),
                            Itertools.fromArraySlice(rand, i, j + 1),
                            func(a : (Nat, Nat), b : (Nat, Nat)) : Bool = a == b,
                        )
                    ) {
                        Debug.print("mismatch: " # debug_show (i, j));
                        Debug.print("range " # debug_show Iter.toArray(BpTree.range(bptree, i, j)));
                        Debug.print("expected " # debug_show Iter.toArray(Itertools.fromArraySlice(rand, i, j + 1)));
                        assert false;
                    };
                };
            };
        },
    );
};

for (order in [4, 32].vals()) {
    suite(
        "B+Tree Test: order " # debug_show order,
        func() = bp_tree_test(order, random),
    );
};
