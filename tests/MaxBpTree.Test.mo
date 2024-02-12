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
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";

import { test; suite } "mo:test";
import Fuzz "mo:fuzz";
import Itertools "mo:itertools/Iter";
import BTree "mo:stableheapbtreemap/BTree";

import Utils "../src/internal/Utils";
import { MaxBpTree } "../src";
import MaxBpTreeMethods "../src/MaxBpTree/Methods";

type Order = Order.Order;

let fuzz = Fuzz.fromSeed(0x7f3a3e7e);

let limit = 1_000;
let data = Buffer.Buffer<(Nat, Nat)>(limit);

for (i in Iter.range(0, limit - 1)) {
    let k = fuzz.nat.randomRange(1, limit * 10);
    let v = fuzz.nat.randomRange(1, limit * 10);
    data.add((k, v));
};

func key_to_hash((a, _) : (Nat, Nat)) : Nat32 = Nat32.fromNat(a);
func tuple_key_equal((a, _) : (Nat, Nat), (b, _) : (Nat, Nat)) : Bool = a == b;

let unique_iter = Itertools.unique<(Nat, Nat)>(data.vals(), key_to_hash, tuple_key_equal);
let random = Itertools.toBuffer<(Nat, Nat)>(unique_iter);
// assert random.size() * 100 > (limit) * 95;

let sorted = Buffer.clone<(Nat, Nat)>(random);
sorted.sort(Utils.tuple_cmp(Nat.compare));

func map_to_entries(iter : Iter.Iter<Nat>) : Iter.Iter<(Nat, Nat)> {
    return Iter.map<Nat, (Nat, Nat)>(iter, func(n : Nat) : (Nat, Nat) = (n, n));
};

func max_bp_tree_test(order : Nat, random : Buffer.Buffer<(Nat, Nat)>, sorted_by_key : Buffer.Buffer<(Nat, Nat)>) {

    let sorted_by_val = Itertools.toBuffer<(Nat, Nat)>(random.vals());
    sorted_by_val.sort(Utils.tuple_cmp_val(Nat.compare));

    test(
        "insert random",
        func() {
            let max_bp_tree = MaxBpTree.new<Nat, Nat>(?order);
            assert max_bp_tree.order == order;

            label for_loop for ((i, (k, v)) in Itertools.enumerate(random.vals())) {
                ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, k, v);

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

            let (init_key, init_val) = random.get(0);
            ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, init_key, init_val);
            var max = (init_key, init_val);

            assert MaxBpTree.maxValue(max_bp_tree) == ?max;

            label for_loop for ((i, (k, v)) in Itertools.enumerate(Itertools.skip(random.vals(), 1))) {

                ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, k, v);

                if (v > max.1) {
                    max := (k, v);
                };

                assert MaxBpTree.maxValue(max_bp_tree) == ?max;
            };
        },
    );

    test(
        "retrieve max value after replacing value",
        func() {

            let max_bp_tree = MaxBpTree.new<Nat, Nat>(?order);
            // let set = TrieMap.TrieMap<Nat, ()>(Nat.equal, Nat32.fromNat);

            let cmp_val = func(a : (Nat, Nat), b : (Nat, Nat)) : Order.Order = Nat.compare(a.1, b.1);

            // entries are flipped to sort by values: (value, key)
            let btree = BTree.init<Nat, Nat>(?order);

            // add entries with unique values
            for ((k, v) in random.vals()) {
                if (not BTree.has(btree, Nat.compare, v)) {
                    ignore BTree.insert<Nat, Nat>(btree, Nat.compare, v, k);
                    ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, k, v);
                };
            };

            let buffer = Itertools.toBuffer<(Nat, Nat)>(
                Iter.map<(Nat, Nat), (Nat, Nat)>(
                    BTree.entries(btree),
                    func((v, k) : (Nat, Nat)) : (Nat, Nat) = (k, v),
                )
            );

            func gen_val() : Nat = fuzz.nat.randomRange(1, limit * 10);

            for (i in Itertools.range(0, buffer.size())) {
                let (key, prev_val) = buffer.get(i);

                var new_val = gen_val();

                while (Option.isSome(BTree.get(btree, Nat.compare, new_val))) {
                    new_val := gen_val();
                };

                let recieved_prev_val = MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, key, new_val);
                assert ?prev_val == recieved_prev_val;

                ignore BTree.delete(btree, Nat.compare, prev_val);
                ignore BTree.insert(btree, Nat.compare, new_val, key);

                // ignore set.remove(prev_val);
                // set.put(new_val, ());

                let ?flipped_max = BTree.max(btree) else Debug.trap("Btree doesn't have max value");
                let actual_max = (flipped_max.1, flipped_max.0);

                let ?recieved = MaxBpTree.maxValue(max_bp_tree) else Debug.trap("max value is null");

                if (actual_max.1 != recieved.1) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected != recieved: " # debug_show (actual_max, recieved));
                    assert false;
                };

            };

        },
    );

    test(
        "maxValue(): replacing entries with lower values",
        func() {
            let sorted_by_val = Itertools.toBuffer<(Nat, Nat)>(random.vals());
            let max_bp_tree = MaxBpTree.fromEntries(?order, sorted_by_val.vals(), Nat.compare, Nat.compare);
            // assert MaxBpTree.size(max_bp_tree) == random.size();
            sorted_by_val.sort(Utils.tuple_cmp_val(Nat.compare));

            let max_vals = Itertools.takeWhile(
                object {
                    public func next() : ?(Nat, Nat) = MaxBpTree.maxValue(max_bp_tree);
                },
                func((k, v) : (Nat, Nat)) : Bool = v > 0,
            );

            for ((i, (k, v)) in Itertools.enumerate(Itertools.take(max_vals, limit))) {
                let expected = v;
                let recieved = MaxBpTree.get(max_bp_tree, Nat.compare, k);

                if (not (?expected == recieved)) {
                    Debug.print("mismatch at key " # debug_show k # " index " # debug_show i);
                    Debug.print("expected != recieved " # debug_show (?expected, recieved));
                    Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                    Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));

                    assert false;
                };

                let expected_max = sorted_by_val.get(sorted_by_val.size() - i - 1);

                if (not (expected_max.1 == v)) {
                    Debug.print("k -> " # debug_show k);
                    Debug.print("expected max -> " # debug_show expected_max);
                    Debug.print("mismatch at key " # debug_show k # " index " # debug_show i);
                    Debug.print("expected != recieved " # debug_show (expected_max, (k, v)));
                    Debug.print("node keys -> " # debug_show MaxBpTree.toNodeKeys(max_bp_tree));
                    Debug.print("leaf nodes -> " # debug_show MaxBpTree.toLeafNodes(max_bp_tree));
                    assert false;
                };

                assert ?v == MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, k, 0);

            };

        },
    );

    test(
        "delete: descending order",
        func() {

            let sorted_by_val = Itertools.toBuffer<(Nat, Nat)>(random.vals());
            sorted_by_val.sort(Utils.tuple_cmp_val(Nat.compare));
            Buffer.reverse(sorted_by_val);

            let max_bp_tree = MaxBpTree.fromEntries(?order, random.vals(), Nat.compare, Nat.compare);
            assert max_bp_tree.order == order;

            label for_loop for ((i, (max_k, max_v)) in Itertools.enumerate(sorted_by_val.vals())) {
                // Debug.print("deleting: " # debug_show (max_k, max_v) # " at index " # debug_show i);
                // Debug.print("expected vs received: " # debug_show ((max_k, max_v), MaxBpTree.maxValue(max_bp_tree)));
                assert ?max_v == MaxBpTree.get(max_bp_tree, Nat.compare, max_k);

                let ?received = MaxBpTree.maxValue(max_bp_tree) else Debug.trap("max value is null");
                assert max_v == received.1;

                assert MaxBpTree.size(max_bp_tree) == (sorted_by_val.size() - i : Nat);

                assert ?max_v == MaxBpTree.remove(max_bp_tree, Nat.compare, Nat.compare, max_k);

                // Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                // Debug.print("leaf nodes: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
            };

            assert MaxBpTree.size(max_bp_tree) == 0;
            assert MaxBpTree.maxValue(max_bp_tree) == null;

        },
    );

    test(
        "delete: insertion order",
        func() {

            let sorted_by_val = Itertools.toBuffer<(Nat, Nat)>(random.vals());
            sorted_by_val.sort(Utils.tuple_cmp_val(Nat.compare));

            let max_bp_tree = MaxBpTree.fromEntries(?order, random.vals(), Nat.compare, Nat.compare);

            let removed_map = TrieMap.TrieMap<Nat, Bool>(Nat.equal, Nat32.fromNat);
            var removed_max_entries = 0;

            var max_index = sorted_by_val.size() - 1 : Nat;

            label for_loop for ((i, (k, v)) in Itertools.enumerate(random.vals())) {
                // Debug.print("removing: ( " # debug_show k # ", " # debug_show v # " ) at index " # debug_show i);
                
                assert ?v == MaxBpTree.get(max_bp_tree, Nat.compare, k);

                let expected = sorted_by_val.get(max_index);
                let ?recieved = MaxBpTree.maxValue(max_bp_tree) else Debug.trap("max value is null");

                if (expected.1 != recieved.1) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected != recieved: " # debug_show (expected, recieved));
                    Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                    Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));

                    assert false;
                };

                assert MaxBpTree.size(max_bp_tree) == (random.size() - i : Nat);

                assert ?v == MaxBpTree.remove(max_bp_tree, Nat.compare, Nat.compare, k);
                removed_map.put(k, true);

                if (v == expected.1) {
                    func is_removed(k : Nat) : Bool = removed_map.get(k) == ?true;

                    while ((max_index >= 1) and is_removed(sorted_by_val.get(max_index).0)) {
                        max_index -= 1;
                    };
                };

            };

            assert MaxBpTree.size(max_bp_tree) == 0;
        },
    );

};

func bptree_tests(order : Nat, random : Buffer.Buffer<(Nat, Nat)>, sorted_by_key : Buffer.Buffer<(Nat, Nat)>) {
    let bptree = MaxBpTree.fromEntries(?order, random.vals(), Nat.compare, Nat.compare);

    test(
        "getIndex",
        func() {
            for (i in Itertools.range(0, sorted_by_key.size())) {
                let (key, _) = sorted_by_key.get(i);
                let rank = MaxBpTree.getIndex(bptree, Nat.compare, key);

                if (not (rank == i)) {
                    Debug.print("sorted_by_key: " # debug_show Buffer.toArray(sorted_by_key));
                    Debug.print("mismatch for key:" # debug_show key);
                    Debug.print("expected != actual:" # debug_show (i, rank));
                    assert false;
                };
            };
        },
    );

    test(
        "getFromIndex",
        func() {
            for (i in Itertools.range(0, sorted_by_key.size())) {
                let expected = sorted_by_key.get(i);
                let received = MaxBpTree.getFromIndex(bptree, i);

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
            let _rand = Iter.toArray<(Nat, Nat)>(Itertools.take(random.vals(), 100));

            let bptree = MaxBpTree.fromEntries(?order, _rand.vals(), Nat.compare, Nat.compare);
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
            let _rand = Iter.toArray<(Nat, Nat)>(Itertools.take(random.vals(), 100));

            let bptree = MaxBpTree.fromEntries(?order, _rand.vals(), Nat.compare, Nat.compare);
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

for (order in [4, 8, 32].vals()) {
    suite(
        "B+Tree tests",
        func() = bptree_tests(order, random, sorted),
    );

    suite(
        "Max B+Tree Test: order " # debug_show order,
        func() = max_bp_tree_test(order, random, sorted),
    );
};
