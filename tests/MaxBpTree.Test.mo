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
import RevIter "mo:itertools/RevIter";
import BTree "mo:stableheapbtreemap/BTree";
import Set "mo:map/Set";

import Utils "../src/internal/Utils";
import { MaxBpTree; Cmp } "../src";
import MaxBpTreeMethods "../src/MaxBpTree/Methods";
import T "../src/MaxBpTree/Types";

type Order = Order.Order;

let { Const = C } = T;

let fuzz = Fuzz.fromSeed(0x7f3a3e7e);
type Buffer<A> = Buffer.Buffer<A>;
type Set<A> = Set.Set<A>;

let { nhash } = Set;

let limit = 10_000;
let data = Buffer.Buffer<(Nat, Nat)>(limit);

for (i in Iter.range(0, limit - 1)) {
    let k = fuzz.nat.randomRange(1, limit * 10);
    let v = fuzz.nat.randomRange(1, 100);
    data.add((k, v));
};

func key_to_hash((a, _) : (Nat, Nat)) : Nat32 = Nat32.fromNat(a);
func tuple_key_equal((a, _) : (Nat, Nat), (b, _) : (Nat, Nat)) : Bool = a == b;

let unique_iter = Itertools.unique<(Nat, Nat)>(data.vals(), key_to_hash, tuple_key_equal);
let random = Itertools.toBuffer<(Nat, Nat)>(unique_iter);
// assert random.size() * 100 > (limit) * 95;

let sorted = Buffer.clone<(Nat, Nat)>(random);
sorted.sort(Utils.tuple_order_cmp_key(Nat.compare));

func map_to_entries(iter : Iter.Iter<Nat>) : Iter.Iter<(Nat, Nat)> {
    return Iter.map<Nat, (Nat, Nat)>(iter, func(n : Nat) : (Nat, Nat) = (n, n));
};

class MaxValueMap(opt_values : ?Buffer.Buffer<(Nat, Nat)>) {
    let btree = BTree.init<Nat, Set<Nat>>(?32);

    public func insert(k : Nat, v : Nat) {
        switch (BTree.has(btree, Nat.compare, v)) {
            case (false) {
                let set : Set<Nat> = Set.new<Nat>();
                ignore Set.put(set, nhash, k);
                ignore BTree.insert<Nat, Set<Nat>>(btree, Nat.compare, v, set);
            };
            case (true) {
                let set = Utils.unwrap(BTree.get(btree, Nat.compare, v), "expected set");
                ignore Set.put(set, nhash, k);
            };
        };
    };

    switch (opt_values) {
        case (?values) {
            for ((k, v) in values.vals()) {
                insert(k, v);
            };
        };
        case (null) {};
    };

    public func remove(k : Nat, v : Nat) {
        let ?set = BTree.get(btree, Nat.compare, v) else Debug.trap("expected set");

        ignore Set.remove(set, nhash, k);

        if (Set.size(set) == 0) {
            ignore BTree.delete(btree, Nat.compare, v);
        };
    };

    public func is_max_val(v : Nat) : Bool {
        switch (BTree.max(btree)) {
            case (null) { return false };
            case (?max) { return max.0 == v };
        };
    };

    public func is_max_key(k : Nat) : Bool {
        switch (BTree.max(btree)) {
            case (null) { return false };
            case (?max) { Set.has(max.1, nhash, k) };
        };
    };

    public func is_max_entry(k : Nat, v : Nat) : Bool {
        switch (BTree.max(btree)) {
            case (null) { return false };
            case (?max) { return max.0 == v and Set.has(max.1, nhash, k) };
        };
    };

    public func max_entry() : ?(Nat, Nat) {
        switch (BTree.max(btree)) {
            case (null) { return null };
            case (?max) {
                let ?k = Set.peek(max.1) else return null;
                ?(k, max.0);
            };
        };
    };
};

func max_bp_tree_test(order : Nat, random : Buffer.Buffer<(Nat, Nat)>, sorted_by_key : Buffer.Buffer<(Nat, Nat)>) {

    let sorted_by_val = Itertools.toBuffer<(Nat, Nat)>(random.vals());
    sorted_by_val.sort(Utils.tuple_order_cmp_val(Nat.compare));

    test(
        "insert random",
        func() {
            let max_bp_tree = MaxBpTree.new<Nat, Nat>(?order);
            assert max_bp_tree.order == order;

            label for_loop for ((i, (k, v)) in Itertools.enumerate(random.vals())) {
                ignore MaxBpTree.insert(max_bp_tree, Cmp.Nat, Cmp.Nat, k, v);
                // Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                // Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));

                let subtree_size = switch (max_bp_tree.root) {
                    case (#branch(node)) { node.0 [C.SUBTREE_SIZE] };
                    case (#leaf(node)) { node.0 [C.COUNT] };
                };

                assert subtree_size == i + 1;

            };

            if (not MaxBpTreeMethods.validate_max_path(max_bp_tree, Cmp.Nat)) {
                // Debug.print("invalid max path discovered at index " # debug_show i);
                // Debug.print("inserting " # debug_show (k, v));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };

            if (not MaxBpTreeMethods.validate_subtree_size(max_bp_tree)) {
                // Debug.print("invalid subtree size at index " # debug_show i);
                // Debug.print("inserting " # debug_show (k, v));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };

            assert MaxBpTree.size(max_bp_tree) == random.size();

            let root_subtree_size = switch (max_bp_tree.root) {
                case (#leaf(node)) node.0 [C.COUNT];
                case (#branch(node)) node.0 [C.SUBTREE_SIZE];
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
            ignore MaxBpTree.insert(max_bp_tree, Cmp.Nat, Cmp.Nat, init_key, init_val);
            var max = (init_key, init_val);

            assert MaxBpTree.maxValue(max_bp_tree) == ?max;

            label for_loop for ((i, (k, v)) in Itertools.enumerate(Itertools.skip(random.vals(), 1))) {

                ignore MaxBpTree.insert(max_bp_tree, Cmp.Nat, Cmp.Nat, k, v);

                if (v > max.1) {
                    max := (k, v);
                };

                switch (MaxBpTree.maxValue(max_bp_tree)) {
                    case (?(_, val)) {
                        // Debug.print("(expected, received) -> " # debug_show (max.1, val));
                        assert val == max.1;
                    };
                    case (null) Debug.trap("max value is null");
                };
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
                    ignore MaxBpTree.insert(max_bp_tree, Cmp.Nat, Cmp.Nat, k, v);
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

                let recieved_prev_val = MaxBpTree.insert(max_bp_tree, Cmp.Nat, Cmp.Nat, key, new_val);
                assert ?prev_val == recieved_prev_val;

                ignore BTree.delete(btree, Nat.compare, prev_val);
                ignore BTree.insert(btree, Nat.compare, new_val, key);

                let ?flipped_max = BTree.max(btree) else Debug.trap("Btree doesn't have max value");
                let actual_max = (flipped_max.1, flipped_max.0);

                let ?recieved = MaxBpTree.maxValue(max_bp_tree) else Debug.trap("max value is null");

                if (actual_max.1 != recieved.1) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected != recieved: " # debug_show (actual_max, recieved));
                    assert false;
                };

            };

            if (not MaxBpTreeMethods.validate_max_path(max_bp_tree, Cmp.Nat)) {
                // Debug.print("invalid max path discovered at index " # debug_show i);
                // Debug.print("replacing " # debug_show (key, prev_val) # " with " # debug_show (key, new_val));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };

            if (not MaxBpTreeMethods.validate_subtree_size(max_bp_tree)) {
                // Debug.print("invalid subtree size discovered at index " # debug_show i);
                // Debug.print("replacing " # debug_show (key, prev_val) # " with " # debug_show (key, new_val));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };

        },
    );

    test(
        "maxValue(): replacing entries with lower values",
        func() {
            let sorted_by_val = Itertools.toBuffer<(Nat, Nat)>(random.vals());
            let max_bp_tree = MaxBpTree.fromEntries(sorted_by_val.vals(), Cmp.Nat, Cmp.Nat, ?order);
            // assert MaxBpTree.size(max_bp_tree) == random.size();
            sorted_by_val.sort(Utils.tuple_order_cmp_val(Nat.compare));

            let max_vals = Itertools.takeWhile(
                object {
                    public func next() : ?(Nat, Nat) = MaxBpTree.maxValue(max_bp_tree);
                },
                func((k, v) : (Nat, Nat)) : Bool = v > 0,
            );

            for ((i, (k, v)) in Itertools.enumerate(Itertools.take(max_vals, limit))) {
                let expected = v;
                let recieved = MaxBpTree.get(max_bp_tree, Cmp.Nat, k);

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

                assert ?v == MaxBpTree.insert(max_bp_tree, Cmp.Nat, Cmp.Nat, k, 0);

            };

            if (not MaxBpTreeMethods.validate_max_path(max_bp_tree, Cmp.Nat)) {
                // Debug.print("invalid max path discovered at index " # debug_show i);
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };

            if (not MaxBpTreeMethods.validate_subtree_size(max_bp_tree)) {
                // Debug.print("invalid subtree size at index " # debug_show i);
                // Debug.print("setting value in " # debug_show (k, v) # " to zero");
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };

        },
    );

    test(
        "removeMaxValue()",
        func() {

            let sorted_by_val = Itertools.toBuffer<(Nat, Nat)>(random.vals());
            sorted_by_val.sort(Utils.tuple_order_cmp_val(Nat.compare));
            Buffer.reverse(sorted_by_val);

            let max_bp_tree = MaxBpTree.fromEntries(random.vals(), Cmp.Nat, Cmp.Nat, ?order);
            assert max_bp_tree.order == order;

            label for_loop for ((i, expected) in Itertools.enumerate(sorted_by_val.vals())) {

                let (max_k, max_v) = expected;

                let ?received = MaxBpTree.maxValue(max_bp_tree) else Debug.trap("max value is null");
                assert max_v == received.1;

                assert MaxBpTree.size(max_bp_tree) == (sorted_by_val.size() - i : Nat);

                let ?removed = MaxBpTree.removeMaxValue(max_bp_tree, Cmp.Nat, Cmp.Nat) else Debug.trap("max value is null");

                // Debug.print("deleting: " # debug_show expected # " at index " # debug_show i);
                // Debug.print("expected vs received: " # debug_show (expected, MaxBpTree.maxValue(max_bp_tree)));
                // Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                // Debug.print("leaf nodes: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));

                if (expected.1 != removed.1) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected != recieved: " # debug_show (expected, removed));
                    Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                    // Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                    assert false;
                };

            };

            if (not MaxBpTreeMethods.validate_max_path(max_bp_tree, Cmp.Nat)) {
                // Debug.print("invalid max path discovered at index " # debug_show i);
                // Debug.print("removing max value " # debug_show (max_k, max_v));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                // Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };

            if (not MaxBpTreeMethods.validate_subtree_size(max_bp_tree)) {
                // Debug.print("invalid subtree size at index " # debug_show i);
                // Debug.print("removing max value " # debug_show (max_k, max_v));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };

            assert MaxBpTree.size(max_bp_tree) == 0;
            assert MaxBpTree.maxValue(max_bp_tree) == null;

        },
    );

    test(
        "removeMin(): test _remove_from_leaf",
        func() {
            let value_map = MaxValueMap(?random);
            let max_bp_tree = MaxBpTree.fromEntries(random.vals(), Cmp.Nat, Cmp.Nat, ?order);

            label for_loop for ((i, expected) in Itertools.enumerate(sorted_by_key.vals())) {
                let (min_key, min_val) = expected;

                let ?expected_max = value_map.max_entry() else Debug.trap("max value is null");
                let ?recieved_max = MaxBpTree.maxValue(max_bp_tree) else Debug.trap("max value is null");

                if (not value_map.is_max_entry(recieved_max)) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected_max != recieved_max: " # debug_show (expected_max, recieved_max));
                    Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                    Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));

                    assert false;
                };

                let ?removed = MaxBpTree.removeMin(max_bp_tree, Cmp.Nat, Cmp.Nat) else Debug.trap("min value is null");

                value_map.remove(removed);

                if (expected != removed) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected != recieved: " # debug_show (expected, removed));
                    Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                    Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));

                    assert false;
                };

                assert MaxBpTree.size(max_bp_tree) == (sorted_by_key.size() - i - 1 : Nat);

            };

        },
    );

    test(
        "delete: insertion order",
        func() {

            let value_map = MaxValueMap(?random);
            let max_bp_tree = MaxBpTree.fromEntries(random.vals(), Cmp.Nat, Cmp.Nat, ?order);
            if (not MaxBpTreeMethods.validate_max_path(max_bp_tree, Cmp.Nat)) {
                // Debug.print("invalid max path discovered at index " # debug_show i);
                // Debug.print("removing " # debug_show (k, v));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };

            if (not MaxBpTreeMethods.validate_subtree_size(max_bp_tree)) {
                // Debug.print("invalid subtree size at index " # debug_show i);
                // Debug.print("removing " # debug_show (k, v));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert false;
            };
            label for_loop for ((i, (k, v)) in Itertools.enumerate(random.vals())) {

                assert ?v == MaxBpTree.get(max_bp_tree, Cmp.Nat, k);

                let ?expected_max = value_map.max_entry() else Debug.trap("max value is null");
                let ?recieved_max = MaxBpTree.maxValue(max_bp_tree) else Debug.trap("max value is null");

                if (not value_map.is_max_entry(recieved_max)) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected_max != recieved_max: " # debug_show (expected_max, recieved_max));
                    Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                    Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));

                    assert false;
                };

                assert MaxBpTree.size(max_bp_tree) == (random.size() - i : Nat);
                // Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bp_tree)));
                // Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bp_tree)));
                assert ?v == MaxBpTree.remove(max_bp_tree, Cmp.Nat, Cmp.Nat, k);
                value_map.remove(k, v);

            };

            assert MaxBpTree.size(max_bp_tree) == 0;
        },
    );

    // todo: check that the tree maintains the max value after replacing a value
    test(
        "test _replace_at_leaf_index()",
        func() {
            let max_bptree = MaxBpTree.fromEntries(random.vals(), Cmp.Nat, Cmp.Nat, ?order);
            let value_map = MaxValueMap(?random);

            label for_loop for ((i, (leaf, j, prev_entry)) in Itertools.enumerate(MaxBpTree.leafEntries(max_bptree).rev())) {
                let (prev_key, prev_val) = prev_entry;
                let new_key = prev_key + 1;
                let new_val = fuzz.nat.randomRange(1, 4);

                // Debug.print("replacing " # debug_show (prev_key, prev_val) # " with " # debug_show (new_key, new_val) # " at index " # debug_show i);

                let ?expected_max = value_map.max_entry() else Debug.trap("max value is null");
                let ?recieved_max = MaxBpTree.maxValue(max_bptree) else Debug.trap("max value is null");

                if (not value_map.is_max_entry(recieved_max)) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected_max != recieved_max: " # debug_show (expected_max, recieved_max));
                    Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bptree)));
                    Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bptree)));

                    assert false;
                };

                assert ?prev_val == MaxBpTree._replace_at_leaf_index(max_bptree, Cmp.Nat, Cmp.Nat, leaf, j, new_key, new_val);

                value_map.remove(prev_key, prev_val);
                value_map.insert(new_key, new_val);

                // Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bptree)));
                // Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bptree)));
            };

            if (not MaxBpTreeMethods.validate_max_path(max_bptree, Cmp.Nat)) {
                // Debug.print("invalid max path discovered at index " # debug_show i);
                // Debug.print("replacing " # debug_show (prev_key, prev_val) # " with " # debug_show (new_key, new_val));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bptree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bptree)));
                assert false;
            };

            if (not MaxBpTreeMethods.validate_subtree_size(max_bptree)) {
                // Debug.print("invalid subtree size discovered at index " # debug_show i);
                // Debug.print("replacing " # debug_show (prev_key, prev_val) # " with " # debug_show (new_key, new_val));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bptree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bptree)));
                assert false;
            };

        },
    );

    test(
        "test _insert_at_leaf_index",
        func() {
            let max_bptree = MaxBpTree.new<Nat, Nat>(?order);
            let value_map = MaxValueMap(null);

            let leftmost_leaf = MaxBpTreeMethods.get_min_leaf_node(max_bptree);

            let entries = RevIter.fromBuffer(sorted_by_key);
            for ((i, (k, v)) in Itertools.enumerate(entries.rev())) {
                // Debug.print("inserting " # debug_show (k, v) # " at index " # debug_show i);

                MaxBpTree._insert_at_leaf_index(max_bptree, Cmp.Nat, Cmp.Nat, leftmost_leaf, 0, k, v);

                value_map.insert(k, v);
                let ?expected_max = value_map.max_entry() else Debug.trap("max value is null");
                let ?recieved_max = MaxBpTree.maxValue(max_bptree) else Debug.trap("max value is null");

                if (not value_map.is_max_entry(recieved_max)) {
                    Debug.print("mismatch at index " # debug_show i);
                    Debug.print("expected_max != recieved_max: " # debug_show (expected_max, recieved_max));
                    Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bptree)));
                    Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bptree)));

                    assert false;
                };
            };

            if (not MaxBpTreeMethods.validate_max_path(max_bptree, Cmp.Nat)) {
                // Debug.print("invalid max path discovered at index " # debug_show i);
                // Debug.print("inserting " # debug_show (k, v));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bptree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bptree)));
                assert false;
            };

            if (not MaxBpTreeMethods.validate_subtree_size(max_bptree)) {
                // Debug.print("invalid subtree size discovered at index " # debug_show i);
                // Debug.print("inserting " # debug_show (k, v));
                Debug.print("node keys: " # debug_show (MaxBpTree.toNodeKeys(max_bptree)));
                Debug.print("node leaves: " # debug_show (MaxBpTree.toLeafNodes(max_bptree)));
                assert false;
            };
        },
    );

};

func bptree_tests(order : Nat, random : Buffer.Buffer<(Nat, Nat)>, sorted_by_key : Buffer.Buffer<(Nat, Nat)>) {
    let bptree = MaxBpTree.fromEntries(random.vals(), Cmp.Nat, Cmp.Nat, ?order);

    test(
        "get",
        func() {
            for ((key, value) in sorted_by_key.vals()) {
                let retrieved = MaxBpTree.get(bptree, Cmp.Nat, key);
                if (?value != retrieved) {
                    Debug.print("mismatch: " # debug_show (?value, retrieved, ?value == retrieved));
                    assert false;
                };
            };
        },
    );

    test(
        "getEntry",
        func() {
            for ((key, value) in sorted_by_key.vals()) {
                let retrieved = MaxBpTree.getEntry(bptree, Cmp.Nat, key);
                if (?(key, value) != retrieved) {
                    Debug.print("mismatch: " # debug_show (?(key, value), retrieved, ?(key, value) == retrieved));
                    assert false;
                };
            };
        },
    );

    test(
        "getIndex",
        func() {
            for (i in Itertools.range(0, sorted_by_key.size())) {
                let (key, _) = sorted_by_key.get(i);
                let rank = MaxBpTree.getIndex(bptree, Cmp.Nat, key);

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

            let bptree = MaxBpTree.fromEntries(_rand.vals(), Cmp.Nat, Cmp.Nat, ?order);
            let rand = Array.sort<(Nat, Nat)>(_rand, Utils.tuple_order_cmp_key(Nat.compare));

            for (i in Itertools.range(0, MaxBpTree.size(bptree))) {

                for (j in Itertools.range(i + 1, MaxBpTree.size(bptree))) {
                    let start_key = rand[i].0;
                    let end_key = rand[j].0;

                    if (
                        not Itertools.equal<(Nat, Nat)>(
                            MaxBpTree.scan(bptree, Cmp.Nat, start_key, end_key),
                            Itertools.fromArraySlice(rand, i, j + 1),
                            func(a : (Nat, Nat), b : (Nat, Nat)) : Bool = a == b,
                        )
                    ) {
                        Debug.print("mismatch: " # debug_show (i, j));
                        Debug.print("scan " # debug_show Iter.toArray(MaxBpTree.scan(bptree, Cmp.Nat, start_key, end_key)));
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

            let bptree = MaxBpTree.fromEntries(_rand.vals(), Cmp.Nat, Cmp.Nat, ?order);
            let rand = Array.sort<(Nat, Nat)>(_rand, Utils.tuple_order_cmp_key(Nat.compare));

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
