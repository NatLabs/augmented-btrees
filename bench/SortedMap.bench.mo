import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import RbTree "mo:base/RBTree";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";

import Bench "mo:bench";
import Fuzz "mo:fuzz";
import BTree "mo:stableheapbtreemap/BTree";
import Map "mo:map/Map";

import { BpTree; MaxBpTree } "../src";

module {

    public func init() : Bench.Bench {
        let fuzz = Fuzz.fromSeed(0xdeadbeef);

        let bench = Bench.Bench();
        bench.name("Comparing RBTree, BTree and B+Tree (BpTree)");
        bench.description("Benchmarking the performance with 10k entries");

        bench.rows(["Map", "RBTree", "BTree", "B+Tree", "Max B+Tree"]);
        bench.cols(["insert()", "replace()", "get()", "entries()", "scan()", "remove()"]);

        let limit = 10_000;
        
        let {nhash} = Map;
        let map = Map.new<Nat, Nat>();
        let btree = BTree.init<Nat, Nat>(?32);
        let bptree = BpTree.new<Nat, Nat>(?32);
        let max_bp_tree = MaxBpTree.new<Nat, Nat>(?32);
        let rbtree = RbTree.RBTree<Nat, Nat>(Nat.compare);

        let entries = Buffer.Buffer<(Nat, Nat)>(limit);
        let replacements = Buffer.Buffer<(Nat, Nat)>(limit);

        for (i in Iter.range(0, limit - 1)) {
            let key = fuzz.nat.randomRange(1, limit ** 3);
            let val = fuzz.nat.randomRange(1, limit ** 3);

            entries.add((key, val));
            replacements.add((key, val * 2));
        };

        let sorted = Buffer.clone(entries);
        sorted.sort(func(a, b) = Nat.compare(a.0, b.0));

        bench.runner(
            func(row, col) = switch (row, col) {
                case ("Map", "insert()") {
                    var i = 0;

                    for ((key, val) in entries.vals()) {
                        ignore Map.put(map, nhash, key, val);
                        i += 1;
                    };
                };
                case ("Map", "replace()") {
                    var i = 0;

                    for ((key, val) in replacements.vals()) {
                        ignore Map.put(map, nhash, key, val);
                        i += 1;
                    };
                };
                case ("Map", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let key = entries.get(i).0;
                        ignore Map.get(map, nhash, key);
                    };
                };
                case ("Map", "entries()") {
                    for (i in rbtree.entries()) { ignore i };
                };
                case ("Map", "scan()") { };
                case ("Map", "remove()") {
                    for (i in Iter.range(0, limit - 1)) {
                        Map.delete(map, nhash, i);
                    };
                };

                case ("RBTree", "insert()") {
                    var i = 0;

                    for ((key, val) in entries.vals()) {
                        rbtree.put(key, val);
                        i += 1;
                    };
                };
                case ("RBTree", "replace()") {
                    var i = 0;

                    for ((key, val) in replacements.vals()) {
                        rbtree.put(key, val);
                        i += 1;
                    };
                };
                case ("RBTree", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let key = entries.get(i).0;
                        ignore rbtree.get(key);
                    };
                };
                case ("RBTree", "entries()") {
                    for (i in rbtree.entries()) { ignore i };
                };
                case ("RBTree", "scan()") { };
                case ("RBTree", "remove()") {
                    for (i in Iter.range(0, limit - 1)) {
                        rbtree.delete(i);
                    };
                };

                case ("BTree", "insert()") {
                    for ((key, val) in entries.vals()) {
                        ignore BTree.insert(btree, Nat.compare, key, val);
                    };
                };
                case ("BTree", "replace()") {
                    for ((key, val) in replacements.vals()) {
                        ignore BTree.insert(btree, Nat.compare, key, val);
                    };
                };
                case ("BTree", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let key = entries.get(i).0;
                        ignore BTree.get(btree, Nat.compare, key);
                    };
                };
                case ("BTree", "entries()") {
                    for (i in BTree.entries(btree)) { ignore i };
                };
                case ("BTree", "scan()") {
                    var i = 0;

                    while (i < limit){
                        let a = sorted.get(i).0;
                        let b = sorted.get(i + 99).0;

                        for (kv in BTree.scanLimit(btree, Nat.compare, a, b, #fwd, 100).results.vals()) { ignore kv };
                        i += 100;
                    };
                };
                case ("BTree", "remove()") {
                    for ((k, v) in entries.vals()) {
                        ignore BTree.delete(btree, Nat.compare, k);
                    };
                };

                case ("B+Tree", "insert()") {
                    for ((key, val) in entries.vals()) {
                        ignore BpTree.insert(bptree, Nat.compare, key, val);
                    };
                };
                case ("B+Tree", "replace()") {
                    for ((key, val) in replacements.vals()) {
                        ignore BpTree.insert(bptree, Nat.compare, key, val);
                    };
                };
                case ("B+Tree", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let key = entries.get(i).0;
                        ignore BpTree.get(bptree, Nat.compare, key);
                    };
                };
                case ("B+Tree", "entries()") {
                    for (kv in BpTree.entries(bptree)) { ignore kv };
                };
                case ("B+Tree", "scan()") {
                    var i = 0;

                    while (i < limit){
                        let a = sorted.get(i).0;
                        let b = sorted.get(i + 99).0;

                        for (kv in BpTree.scan(bptree, Nat.compare, a, b)) { ignore kv };
                        i += 100;
                    };
                };
                case ("B+Tree", "remove()") {
                    for ((k, v) in entries.vals()) {
                        ignore BpTree.remove(bptree, Nat.compare, k);
                    };
                };

                case ("Max B+Tree", "insert()") {
                    for ((key, val) in entries.vals()) {
                        ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, key, val);
                    };
                };
                case ("Max B+Tree", "replace()") {
                    for ((key, val) in replacements.vals()) {
                        ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, key, val);
                    };
                };
                case ("Max B+Tree", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let key = entries.get(i).0;
                        ignore MaxBpTree.get(max_bp_tree, Nat.compare, key);
                    };
                 };
                case ("Max B+Tree", "entries()") {
                    for (kv in MaxBpTree.entries(max_bp_tree)) { ignore kv };
                };
                case ("Max B+Tree", "scan()") {
                    var i = 0;

                    while (i < limit){
                        let a = sorted.get(i).0;
                        let b = sorted.get(i + 99).0;

                        for (kv in MaxBpTree.scan(max_bp_tree, Nat.compare, a, b)) { ignore kv };
                        i += 100;
                    };
                };
                case ("Max B+Tree", "remove()") { 
                    for ((k, v) in entries.vals()) {
                        ignore MaxBpTree.remove(max_bp_tree, Nat.compare, Nat.compare, k);
                    };
                };

                case (_) {
                    Debug.trap("Should not reach with row = " # debug_show row # " and col = " # debug_show col);
                };
            }
        );

        bench;
    };
};
