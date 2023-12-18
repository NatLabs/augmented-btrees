import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Order "mo:base/Order";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import TrieSet "mo:base/TrieSet";
import TrieMap "mo:base/TrieMap";
import Heap "mo:base/Heap";

import { test; suite } "mo:test";
import Fuzz "mo:fuzz";
import Itertools "mo:itertools/Iter";
import BTree "mo:stableheapbtreemap/BTree";

import Utils "../src/internal/Utils";
import { MaxBpTree } "../src";
import InternalMethods "../src/internal/Methods";

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

let sorted = Buffer.clone(random);
sorted.sort(Nat.compare);

func max_bp_tree_test(order : Nat, random : Buffer.Buffer<Nat>, sorted : Buffer.Buffer<Nat>) {
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

    test(
        "retrieve max value",
        func() {
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
        },
    );

    test(
        "retrieve max value after replacing value",
        func() {
            
            let max_bp_tree = MaxBpTree.new<Nat, Nat>(?order);
            let set = TrieMap.TrieMap<Nat, ()>(Nat.equal, Nat32.fromNat);

            let cmp_val = func (a: (Nat, Nat), b: (Nat, Nat)) : Order.Order = Nat.compare(a.1, b.1);

            // entries are flipped to sort by values: (value, key)
            let btree = BTree.init<Nat, Nat>(?order);

            for (val in random.vals()){
                let k = val; let v = val;
                ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, k, v);

                set.put(v, ());
                ignore BTree.insert<Nat, Nat>(btree, Nat.compare, v, k);
            };

            for (i in Itertools.range(0, random.size())){
                let key = random.get(i);
                let prev_val = key;

                func gen_val(): Nat = fuzz.nat.randomRange(1, limit * 100);

                var rand_val = gen_val();

                while (set.get(rand_val) == ?()){
                    rand_val := gen_val();
                };

                assert ?prev_val == MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, key, rand_val);

                ignore BTree.delete(btree, Nat.compare, prev_val);
                ignore BTree.insert(btree, Nat.compare, rand_val, key);

                ignore set.remove(prev_val);
                set.put(rand_val, ());

                let ?flipped_max = BTree.max(btree);
                let actual_max = (flipped_max.1, flipped_max.0);
                assert ?actual_max == MaxBpTree.maxValue(max_bp_tree);

            };
        },
    );

    test(
        "delete: descending order",
        func() {
            let iter_entries = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let max_bp_tree = MaxBpTree.fromEntries<Nat, Nat>(?order, iter_entries, Nat.compare, Nat.compare);
            assert max_bp_tree.order == order;

            label for_loop for (i in Itertools.range(0, sorted.size())) {
                let max = sorted.get(sorted.size() - i - 1);

                assert ?max == MaxBpTree.get(max_bp_tree, Nat.compare, max);
                assert ?(max, max) == MaxBpTree.maxValue(max_bp_tree);
                assert MaxBpTree.size(max_bp_tree) == (sorted.size() - i : Nat);

                assert ?max == MaxBpTree.remove(max_bp_tree, Nat.compare, Nat.compare, max);
            };

            assert MaxBpTree.size(max_bp_tree) == 0;
            assert MaxBpTree.maxValue(max_bp_tree) == null;

        },
    );

    test(
        "delete: insertion order",
        func() {
            let iter_entries = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let max_bp_tree = MaxBpTree.fromEntries<Nat, Nat>(?order, iter_entries, Nat.compare, Nat.compare);

            let removed_map = TrieMap.TrieMap<Nat, Bool>(Nat.equal, Nat32.fromNat);
            var removed_max_entries = 0;

            var max_index = sorted.size() - 1 : Nat;

            label for_loop for ((i, v) in Itertools.enumerate(random.vals())) {

                let max = sorted.get(max_index);
                let leaf_node = InternalMethods.get_leaf_node(max_bp_tree, Nat.compare, max);

                assert ?v == MaxBpTree.get(max_bp_tree, Nat.compare, v);

                let expected = ?(max, max);
                let received = MaxBpTree.maxValue(max_bp_tree);

                if (not (expected == received)) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected != received: " # debug_show (expected, received));
                    assert false;
                };

                assert MaxBpTree.size(max_bp_tree) == (random.size() - i : Nat);

                assert ?v == MaxBpTree.remove(max_bp_tree, Nat.compare, Nat.compare, v);
                removed_map.put(v, true);

                if (v == max) {
                    func is_removed(n : Nat) : Bool = removed_map.get(n) == ?true;

                    while ((max_index >= 1) and is_removed(sorted.get(max_index))) {
                        max_index -= 1;
                    };

                };

            };

            assert MaxBpTree.size(max_bp_tree) == 0;
        },
    );

};

func bptree_tests(order : Nat, random : Buffer.Buffer<Nat>, sorted : Buffer.Buffer<Nat>) {
    let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
    let bptree = MaxBpTree.fromEntries<Nat, Nat>(?order, iter, Nat.compare, Nat.compare);

    test(
        "getRank",
        func() {
            for (i in Itertools.range(0, sorted.size())) {
                let key = sorted.get(i);
                let rank = MaxBpTree.getRank(bptree, Nat.compare, key);

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
            for (i in Itertools.range(0, sorted.size())) {
                let expected = sorted.get(i);
                let received = MaxBpTree.getByRank(bptree, i);

                if (not ((expected, expected) == received)) {
                    Debug.print("mismatch at rank:" # debug_show i);
                    Debug.print("expected != received: " # debug_show ((expected, expected), received));
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

            let bptree = MaxBpTree.fromEntries<Nat, Nat>(?order, _rand.vals(), Nat.compare, Nat.compare);
            let rand = Array.sort<(Nat, Nat)>(_rand, Utils.tuple_cmp(Nat.compare));

            for (i in Itertools.range(0, MaxBpTree.size(bptree))) {

                for (j in Itertools.range(i + 1, MaxBpTree.size(bptree))) {
                    let start_key = rand[i].0;
                    let end_key = rand[j].0;

                    if (
                        not Itertools.equal<(Nat, Nat)>(
                            MaxBpTree.scan(bptree, Nat.compare, start_key, end_key),
                            Itertools.fromArraySlice(rand, i, j + 1),
                            func(a : (Nat, Nat), b : (Nat, Nat)) : Bool = a == b,
                        )
                    ) {
                        Debug.print("mismatch: " # debug_show (i, j));
                        Debug.print("scan " # debug_show Iter.toArray(MaxBpTree.scan(bptree, Nat.compare, start_key, end_key)));
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

            let bptree = MaxBpTree.fromEntries<Nat, Nat>(?order, _rand.vals(), Nat.compare, Nat.compare);
            let rand = Array.sort<(Nat, Nat)>(_rand, Utils.tuple_cmp(Nat.compare));

            for (i in Itertools.range(0, MaxBpTree.size(bptree))) {

                for (j in Itertools.range(i + 1, MaxBpTree.size(bptree))) {

                    if (
                        not Itertools.equal<(Nat, Nat)>(
                            MaxBpTree.range(bptree, i, j),
                            Itertools.fromArraySlice(rand, i, j + 1),
                            func(a : (Nat, Nat), b : (Nat, Nat)) : Bool = a == b,
                        )
                    ) {
                        Debug.print("mismatch: " # debug_show (i, j));
                        Debug.print("range " # debug_show Iter.toArray(MaxBpTree.range(bptree, i, j)));
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
        "B+Tree tests",
        func() = bptree_tests(order, random, sorted),
    );

    suite(
        "Max B+Tree Test: order " # debug_show order,
        func() = max_bp_tree_test(order, random, sorted),
    );
};
