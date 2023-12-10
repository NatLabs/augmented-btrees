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

import { BpTree } "../src";

module {

    public func init() : Bench.Bench {
        let fuzz = Fuzz.Fuzz();

        let bench = Bench.Bench();
        bench.name("Comparing RBTree, BTree and B+Tree (BpTree)");
        bench.description("Benchmarking the performance with 10k entries");

        bench.rows(["RBTree", "BTree", "B+Tree"]);
        bench.cols(["insert()", "replace()", "get()", "entries()", "delete()"]);

        let limit = 10_000;

        let btree = BTree.init<Nat, Nat>(?32);
        let bptree = BpTree.new<Nat, Nat>(?32);
        let rbtree = RbTree.RBTree<Nat, Nat>(Nat.compare);

        let entries = Buffer.Buffer<(Nat, Nat)>(limit);

        for (i in Iter.range(0, limit - 1)) {
            let key = fuzz.nat.randomRange(1, limit ** 3);

            entries.add((key, i));
        };

        bench.runner(
            func(row, col) = switch (row, col) {

                case ("RBTree", "insert()") {
                    var i = 0;

                    for ((key, val) in entries.vals()) {
                        rbtree.put(key, val);
                        i += 1;
                    };
                };
                case ("RBTree", "replace()") {
                    var i = 0;

                    for ((key, val) in entries.vals()) {
                        rbtree.put(key, val * 2);
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
                case ("RBTree", "delete()") {
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
                    for ((key, val) in entries.vals()) {
                        ignore BTree.insert(btree, Nat.compare, key, val * 2);
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
                case ("BTree", "delete()") {
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
                    for ((key, val) in entries.vals()) {
                        ignore BpTree.insert(bptree, Nat.compare, key, val * 2);
                    };
                };
                case ("B+Tree", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let key = entries.get(i).0;
                        ignore BpTree.get(bptree, Nat.compare, key);
                    };
                };
                case ("B+Tree", "entries()") {
                    for (i in BpTree.entries(bptree)) { ignore i };
                };
                case ("B+Tree", "delete()") {
                    for ((k, v) in entries.vals()) {
                        ignore BpTree.remove(bptree, Nat.compare, k);
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
