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
import InternalMethods "../src/internal/Methods";

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

    let sorted = Buffer.clone(random);
    random.sort(Nat.compare);

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

    test("delete: insertion order", func () {
        let iter_entries = Iter.map<Nat, (Nat, Nat)>(random.vals(), func (n: Nat): (Nat, Nat) = (n, n));

        let max_bp_tree = MaxBpTree.fromEntries<Nat, Nat>(?order, iter_entries, Nat.compare, Nat.compare);
        assert max_bp_tree.order == order;

        var removed_max_entries = 0;
        label for_loop for ((i, v) in Itertools.enumerate(random.vals())) {

            let max = random.get(random.size() - removed_max_entries - 1);
            let leaf_node = InternalMethods.get_leaf_node(max_bp_tree, Nat.compare, max);
            
            assert ?max == MaxBpTree.get(max_bp_tree, Nat.compare, max);
            assert ?(max, max) == MaxBpTree.maxValue(max_bp_tree);
            assert MaxBpTree.size(max_bp_tree) == (random.size() - i: Nat);

            assert ?v == MaxBpTree.remove(max_bp_tree, Nat.compare, Nat.compare, v);
            if (v == max)  removed_max_entries += 1;
        };

        assert MaxBpTree.size(max_bp_tree) == 0;
    });

    test("delete: descending order", func () {
        let iter_entries = Iter.map<Nat, (Nat, Nat)>(random.vals(), func (n: Nat): (Nat, Nat) = (n, n));

        let max_bp_tree = MaxBpTree.fromEntries<Nat, Nat>(?order, iter_entries, Nat.compare, Nat.compare);
        assert max_bp_tree.order == order;

        label for_loop for (i in Itertools.range(0, random.size())) {
            let max = random.get(random.size() - i - 1);

            assert ?max == MaxBpTree.get(max_bp_tree, Nat.compare, max);
            assert ?(max, max) == MaxBpTree.maxValue(max_bp_tree);
            assert MaxBpTree.size(max_bp_tree) == (random.size() - i: Nat);

            assert ?max == MaxBpTree.remove(max_bp_tree, Nat.compare, Nat.compare, max);
        };

        assert MaxBpTree.size(max_bp_tree) == 0;
    });

    suite("B+Tree tests", func (){
        bptree_tests(order, random);
    });
};

func bptree_tests(order : Nat, random : Buffer.Buffer<Nat>){
     test(
        "getRank",
        func() {
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(Itertools.take(iter, 1000));

            let bptree = MaxBpTree.fromEntries<Nat, Nat>(?4, rand.vals(), Nat.compare, Nat.compare);

            rand.sort(Utils.tuple_cmp(Nat.compare));

            for (i in Itertools.range(0, rand.size())) {
                let key = rand.get(i).0;
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
            let iter = Iter.map<Nat, (Nat, Nat)>(random.vals(), func(n : Nat) : (Nat, Nat) = (n, n));
            let rand = Itertools.toBuffer<(Nat, Nat)>(Itertools.take(iter, 1000));

            let bptree = MaxBpTree.fromEntries<Nat, Nat>(?4, rand.vals(), Nat.compare, Nat.compare);

            rand.sort(Utils.tuple_cmp(Nat.compare));

            for (i in Itertools.range(0, rand.size())) {
                let expected = rand.get(i);
                let received = MaxBpTree.getByRank(bptree, i);

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

            let bptree = MaxBpTree.fromEntries<Nat, Nat>(?4, _rand.vals(), Nat.compare, Nat.compare);
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

            let bptree = MaxBpTree.fromEntries<Nat, Nat>(?4, _rand.vals(), Nat.compare, Nat.compare);
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
        "Max B+Tree Test: order " # debug_show order,
        func() = max_bp_tree_test(order, random),
    );
};
