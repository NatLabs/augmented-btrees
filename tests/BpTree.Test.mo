import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";

import { test; suite } "mo:test";
import Fuzz "mo:fuzz";
import Itertools "mo:itertools/Iter";

import { BpTree; Cmp } "../src";
import Utils "../src/internal/Utils";
import BpTreeMethods "../src/BpTree/Methods";
import ArrayMut "../src/internal/ArrayMut";
import Leaf "../src/BpTree/Leaf";
import Types "../src/BpTree/Types";

import { Const = C } "../src/BpTree/Types";

type Order = Order.Order;

let fuzz = Fuzz.fromSeed(0x7f3a3e7e);

let limit = 1_000;
let data = Buffer.Buffer<Nat>(limit);

for (i in Iter.range(0, limit - 1)) {
    let n = fuzz.nat.randomRange(1, limit * 10);
    data.add(n);
};

let unique_iter = Itertools.unique<Nat>(data.vals(), Nat32.fromNat, Nat.equal);
let random = Itertools.toBuffer<Nat>(unique_iter);
// assert random.size() * 100 > (limit) * 95;

func map_to_entries(iter : Iter.Iter<Nat>) : Iter.Iter<(Nat, Nat)> {
    return Iter.map<Nat, (Nat, Nat)>(iter, func(n : Nat) : (Nat, Nat) = (n, n));
};

func bp_tree_test(order : Nat, random : Buffer.Buffer<Nat>) {

    let sorted = Buffer.clone(random);
    sorted.sort(Nat.compare);

    let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
    let bptree = BpTree.fromEntries<Nat, Nat>(iter, Cmp.Nat, ?order);

    test(
        "insert random",
        func() {
            let bptree = BpTree.new<Nat, Nat>(?order);
            assert bptree.order == order;
            // Debug.print("random size " # debug_show random.size());
            label for_loop for ((i, v) in Itertools.enumerate(random.vals())) {
                ignore BpTree.insert(bptree, Cmp.Nat, v, v);
                // Debug.print("keys " # debug_show BpTree.toNodeKeys(bptree));
                // Debug.print("leafs " # debug_show BpTree.toLeafNodes(bptree));

                let subtree_size = switch (bptree.root) {
                    case (#branch(node)) { node.0 [C.SUBTREE_SIZE] };
                    case (#leaf(node)) { node.0 [C.COUNT] };
                };

                assert subtree_size == i + 1;
            };

            assert BpTree.size(bptree) == random.size();
            // validate root subtree_size
            let root_subtree_size = switch (bptree.root) {
                case (#leaf(node)) node.0 [C.COUNT];
                case (#branch(node)) node.0 [C.SUBTREE_SIZE];
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
        "insert() for replacing entries",
        func() {
            let bptree = BpTree.fromEntries<Nat, Nat>(map_to_entries(random.vals()), Cmp.Nat, ?order);
            assert BpTree.size(bptree) == random.size();

            for ((k, v) in map_to_entries(random.vals())) {
                let choice = fuzz.nat.randomRange(0, 1);
                let new_value = if (choice == 0) (v / 10) else (v * 10);
                assert ?v == BpTree.insert(bptree, Cmp.Nat, k, new_value);
            };
        },
    );

    test(
        "delete with ascending order",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(iter);
            rand.sort(func(a : (Nat, Nat), b : (Nat, Nat)) : Order = Nat.compare(a.0, b.0));

            let bptree = BpTree.fromEntries<Nat, Nat>(rand.vals(), Cmp.Nat, ?order);
            assert BpTree.size(bptree) == rand.size();

            label _l for ((i, (k, v)) in Itertools.enumerate(rand.vals())) {

                // Debug.print("deleting " # debug_show k # " at index " # debug_show i);
                let removed = BpTree.remove(bptree, Cmp.Nat, k);
                if (?v != removed) {
                    Debug.print("mismatch: " # debug_show (?v, removed, ?v == removed) # " at index " # debug_show i);
                    assert false;
                };

                assert BpTree.size(bptree) == (rand.size() - i - 1 : Nat);

                let root_subtree_size = switch (bptree.root) {
                    case (#branch(node)) { node.0 [C.SUBTREE_SIZE] };
                    case (#leaf(node)) { node.0 [C.COUNT] };
                };

                assert root_subtree_size == (rand.size() - i - 1 : Nat);
            };

            assert BpTree.size(bptree) == 0;
        },
    );

    assert BpTree.size(bptree) == random.size();

    test(
        "delete with descending order",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(iter);
            rand.sort(func(a : (Nat, Nat), b : (Nat, Nat)) : Order = Nat.compare(b.0, a.0));
            let bptree = BpTree.fromEntries<Nat, Nat>(rand.vals(), Cmp.Nat, ?order);
            assert BpTree.size(bptree) == rand.size();

            label _l for ((i, n) in Itertools.enumerate(sorted.vals())) {

                // Debug.print("deleting " # debug_show k # " at index " # debug_show i);
                let removed = BpTree.remove(bptree, Cmp.Nat, n);
                if (?n != removed) {
                    Debug.print("mismatch: " # debug_show (?n, removed, ?n == removed) # " at index " # debug_show i);
                    assert false;
                };

                assert BpTree.size(bptree) == (sorted.size() - i - 1 : Nat);

                let root_subtree_size = switch (bptree.root) {
                    case (#branch(node)) { node.0 [C.SUBTREE_SIZE] };
                    case (#leaf(node)) { node.0 [C.COUNT] };
                };

                assert root_subtree_size == (sorted.size() - i - 1 : Nat);
            };

            assert BpTree.size(bptree) == 0;
        },
    );

    test(
        "get",
        func() {
            for (n in random.vals()) {
                let retrieved = BpTree.get(bptree, Cmp.Nat, n);
                if (?n != retrieved) {
                    Debug.print("mismatch: " # debug_show (?n, retrieved, ?n == retrieved));
                    assert false;
                };
            };
        },
    );

    test(
        "getIndex",
        func() {

            for (i in Itertools.range(0, sorted.size())) {
                let key = sorted.get(i);

                let expected = i;
                let rank = BpTree.getIndex(bptree, Cmp.Nat, key);
                // Debug.print("(key. expected, rank) -> " # debug_show (key, expected, rank));
                if (not (rank == expected)) {
                    Debug.print("mismatch for key:" # debug_show key);
                    Debug.print("expected != rank: " # debug_show (expected, rank));
                    assert false;
                };
            };
        },
    );

    test(
        "getExpectedIndex",
        func() {

            for (i in Itertools.range(0, sorted.size())) {
                let key = sorted.get(i);

                let expected = #Found(i);
                let rank = BpTree.getExpectedIndex(bptree, Cmp.Nat, key);

                if (not (rank == expected)) {
                    Debug.print("getIndex -> " # debug_show (BpTree.getIndex(bptree, Cmp.Nat, key)));
                    Debug.print("mismatch for key:" # debug_show key);
                    Debug.print("expected != rank: " # debug_show (expected, rank));
                    assert false;
                };
            };

            let non_consecutive_range = Itertools.add(
                Iter.map(
                    Iter.filter(
                        Itertools.slidingTuples(Itertools.range(0, sorted.size())),
                        func((i, j) : (Nat, Nat)) : Bool = sorted.get(i) + 1 != sorted.get(j),
                    ),
                    func((i, j) : (Nat, Nat)) : Nat = i,
                ),
                sorted.size() - 1 : Nat,
            );

            assert #NotFound(0) == BpTree.getExpectedIndex(bptree, Cmp.Nat, 0);

            for (i in non_consecutive_range) {
                let key = sorted.get(i) + 1;

                let expected = #NotFound(i + 1);
                let rank = BpTree.getExpectedIndex(bptree, Cmp.Nat, key);

                if (not (rank == expected)) {
                    Debug.print("getIndex -> " # debug_show (BpTree.getIndex(bptree, Cmp.Nat, key)));
                    Debug.print("mismatch for key:" # debug_show key);
                    Debug.print("expected != rank: " # debug_show (expected, rank));
                    assert false;
                };
            };
        },
    );

    test(
        "getFromIndex",
        func() {
            for (i in Itertools.range(0, sorted.size())) {
                let expected = sorted.get(i);
                let received = BpTree.getFromIndex(bptree, i);

                if (not ((expected, expected) == received)) {
                    Debug.print("mismatch at rank:" # debug_show i);
                    Debug.print("expected != received: " # debug_show ((expected, expected), received));
                    assert false;
                };
            };
        },
    );

    test(
        "getFloor()",
        func() {

            let sorted = Itertools.range(1, limit)
            |> Iter.map<Nat, Nat>(_, func(n : Nat) : Nat = 2 * n)
            |> Itertools.toBuffer<Nat>(_);

            let bptree = Iter.map<Nat, (Nat, Nat)>(sorted.vals(), func(n : Nat) : (Nat, Nat) = (n, n))
            |> BpTree.fromEntries<Nat, Nat>(_, Cmp.Nat, ?order);

            for (i in Itertools.range(0, sorted.size())) {
                var key = sorted.get(i);

                let expected = sorted.get(i);
                let received = BpTree.getFloor(bptree, Cmp.Nat, key);

                if (not (?(expected, expected) == received)) {
                    Debug.print("mismatch at key:" # debug_show key);
                    Debug.print("expected != received: " # debug_show (expected, received));
                    assert false;
                };

                let prev = key - 1;

                if (i > 0) {
                    let expected = sorted.get(i - 1);
                    let received = BpTree.getFloor(bptree, Cmp.Nat, prev);

                    if (not (?(expected, expected) == received)) {
                        Debug.print("mismatch at key:" # debug_show prev);
                        Debug.print("expected != received: " # debug_show (expected, received));
                        assert false;
                    };
                } else {
                    assert BpTree.getFloor(bptree, Cmp.Nat, prev) == null;
                };

                let next = key + 1;

                do {
                    let expected = sorted.get(i);
                    let received = BpTree.getFloor(bptree, Cmp.Nat, next);

                    if (not (?(expected, expected) == received)) {
                        Debug.print("mismatch at key:" # debug_show next);
                        Debug.print("expected != received: " # debug_show (expected, received));
                        assert false;
                    };
                };

            };
        },
    );

    test(
        "getCeiling()",
        func() {
            let sorted = Itertools.range(1, limit)
            |> Iter.map<Nat, Nat>(_, func(n : Nat) : Nat = 2 * n)
            |> Itertools.toBuffer<Nat>(_);

            let bptree = Iter.map<Nat, (Nat, Nat)>(sorted.vals(), func(n : Nat) : (Nat, Nat) = (n, n))
            |> BpTree.fromEntries<Nat, Nat>(_, Cmp.Nat, ?order);

            for (i in Itertools.range(0, sorted.size())) {
                var key = sorted.get(i);

                let expected = sorted.get(i);
                let received = BpTree.getCeiling(bptree, Cmp.Nat, key);

                if (not (?(expected, expected) == received)) {
                    Debug.print("mismatch at key:" # debug_show key);
                    Debug.print("expected != received: " # debug_show (expected, received));
                    assert false;
                };

                let prev = key - 1;

                do {
                    let expected = sorted.get(i);
                    let received = BpTree.getCeiling(bptree, Cmp.Nat, prev);

                    if (not (?(expected, expected) == received)) {
                        Debug.print("mismatch at key:" # debug_show prev);
                        Debug.print("expected != received: " # debug_show (expected, received));
                        assert false;
                    };
                };

                let next = key + 1;

                if (i + 1 < sorted.size()) {
                    let expected = sorted.get(i + 1);
                    let received = BpTree.getCeiling(bptree, Cmp.Nat, next);

                    if (not (?(expected, expected) == received)) {
                        Debug.print("mismatch at key:" # debug_show next);
                        Debug.print("expected != received: " # debug_show (expected, received));
                        assert false;
                    };
                } else {
                    assert BpTree.getCeiling(bptree, Cmp.Nat, next) == null;
                };

            };
        },
    );

    test(
        "entries.rev()",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let bptree = BpTree.fromEntries<Nat, Nat>(iter, Cmp.Nat, ?order);

            let rand = Buffer.clone(sorted);
            Buffer.reverse(rand);
            assert BpTree.size(bptree) == rand.size();

            let entries = BpTree.entries(bptree);
            for ((i, (k, v)) in Itertools.enumerate(entries.rev())) {
                let expected = rand.get(i);

                if (v != expected) {
                    Debug.print("mismatch: (" # debug_show i # ") ->" # debug_show (v, expected, v == expected));
                    Debug.print("revEntries " # debug_show Iter.toArray(BpTree.entries(bptree).rev()));
                    assert false;
                };
            };

            while (rand.size() > 1) {
                let index = fuzz.nat.randomRange(0, rand.size() - 1);
                let n = rand.remove(index);
                assert ?n == BpTree.remove(bptree, Cmp.Nat, n);

                assert Itertools.equal<(Nat, Nat)>(
                    map_to_entries(rand.vals()),
                    BpTree.entries(bptree).rev(),
                    func(a : (Nat, Nat), b : (Nat, Nat)) : Bool = a == b,
                );
            };

            assert BpTree.entries(bptree).next() == ?(rand.get(0), rand.get(0));
        },
    );

    test(
        "scan",
        func() {
            let sliding_tuples = Itertools.range(0, BpTree.size(bptree))
            |> Iter.map<Nat, Nat>(_, func(n : Nat) : Nat = n * 100)
            |> Itertools.takeWhile(_, func(n : Nat) : Bool = n < BpTree.size(bptree))
            |> Itertools.slidingTuples(_);

            for ((i, j) in sliding_tuples) {
                let start_key = sorted.get(i);
                let end_key = sorted.get(j);

                var index = i;

                for ((k, v) in BpTree.scan(bptree, Cmp.Nat, ?start_key, ?end_key)) {
                    let expected = sorted.get(index);

                    if (not (expected == k)) {
                        Debug.print("mismatch: " # debug_show (expected, k));
                        Debug.print("scan " # debug_show Iter.toArray(BpTree.scan(bptree, Cmp.Nat, ?start_key, ?end_key)));

                        let expected_vals = Iter.range(i, j)
                        |> Iter.map<Nat, Nat>(_, func(n : Nat) : Nat = sorted.get(n));
                        Debug.print("expected " # debug_show Iter.toArray(expected_vals));
                        assert false;
                    };

                    index += 1;
                };
            };
        },
    );

    test(
        "range",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let _rand = Iter.toArray<(Nat, Nat)>(Itertools.take(iter, 100));

            let bptree = BpTree.fromEntries<Nat, Nat>(_rand.vals(), Cmp.Nat, ?order);
            let rand = Array.sort<(Nat, Nat)>(_rand, Utils.tuple_order_cmp_key(Nat.compare));

            for (i in Itertools.range(0, BpTree.size(bptree))) {

                for (j in Itertools.range(i + 1, BpTree.size(bptree))) {

                    if (
                        not Itertools.equal<(Nat, Nat)>(
                            BpTree.range(bptree, i, j),
                            Itertools.fromArraySlice(rand, i, j),
                            func(a : (Nat, Nat), b : (Nat, Nat)) : Bool = a == b,
                        )
                    ) {
                        Debug.print("mismatch: " # debug_show (i, j));
                        Debug.print("range " # debug_show Iter.toArray(BpTree.range(bptree, i, j)));
                        Debug.print("expected " # debug_show Iter.toArray(Itertools.fromArraySlice(rand, i, j)));
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
