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

        // let btree = BTree.init<Nat, Nat>(?32);
        // let bptree = BpTree.newWithOrder<Nat, Nat>(32);
        // let rbtree = RbTree.RBTree<Nat, Nat>(Nat.compare);

        // let insert_entries = Buffer.Buffer<(Nat, Nat)>(limit);

        // for (i in Iter.range(0, limit - 1)) {
        //     let key = fuzz.nat.randomRange(1, limit ** 3);

        //     insert_entries.add((key, i));
        // };

        // bench.runner(
        //     func(row, col) = switch (row, col) {

        //         case ("RBTree", "insert()") {
        //             var i = 0;

        //             for ((key, val) in insert_entries.vals()) {
        //                 rbtree.put(key, val);
        //                 i += 1;
        //             };
        //         };
        //         case ("RBTree", "replace()") {
        //             var i = 0;

        //             for ((key, val) in insert_entries.vals()) {
        //                 rbtree.put(key, val * 2);
        //                 i += 1;
        //             };
        //         };
        //         case ("RBTree", "get()") {
        //             for (i in Iter.range(0, limit - 1)) {
        //                 let key = insert_entries.get(i).0;
        //                 ignore rbtree.get(key);
        //             };
        //         };
        //         case ("RBTree", "entries()") {
        //             for (i in rbtree.entries()) { ignore i };
        //         };
        //         case ("RBTree", "delete()") {
        //             for (i in Iter.range(0, limit - 1)) {
        //                 rbtree.delete(i);
        //             };
        //         };

        //         case ("BTree", "insert()") {
        //             var i = 0;

        //             for ((key, val) in insert_entries.vals()) {
        //                 ignore BTree.insert(btree, Nat.compare, key, val);
        //                 i += 1;
        //             };
        //         };
        //         case ("BTree", "replace()") {
        //             var i = 0;

        //             for ((key, val) in insert_entries.vals()) {
        //                 ignore BTree.insert(btree, Nat.compare, key, val * 2);
        //                 i += 1;
        //             };
        //         };
        //         case ("BTree", "get()") {
        //             for (i in Iter.range(0, limit - 1)) {
        //                 let key = insert_entries.get(i).0;
        //                 ignore BTree.get(btree, Nat.compare, key);
        //             };
        //         };
        //         case ("BTree", "entries()") {
        //             for (i in BTree.entries(btree)) { ignore i };
        //         };
        //         case ("BTree", "delete()") {
        //             for (i in Iter.range(0, limit - 1)) {
        //                 ignore BTree.delete(btree, Nat.compare, i);
        //             };
        //         };

        //         case ("B+Tree", "insert()") {
        //             var i = 0;

        //             for ((key, val) in insert_entries.vals()) {
        //                 ignore BpTree.insert(bptree, Nat.compare, key, val);
        //                 i += 1;
        //             };
        //         };
        //         case ("B+Tree", "replace()") {
        //             var i = 0;

        //             for ((key, val) in insert_entries.vals()) {
        //                 ignore BpTree.insert(bptree, Nat.compare, key, val * 2);
        //                 i += 1;
        //             };
        //         };
        //         case ("B+Tree", "get()") {
        //             for (i in Iter.range(0, limit - 1)) {
        //                 let key = insert_entries.get(i).0;
        //                 ignore BpTree.get(bptree, Nat.compare, key);
        //             };
        //         };
        //         case ("B+Tree", "entries()") {
        //             for (i in BpTree.entries(bptree)) { ignore i };
        //         };
        //         case ("B+Tree", "delete()") {
        //             // for (i in Iter.range(0, limit - 1)) {
        //             //     ignore BTree.delete(btree, Nat.compare, i);
        //             // };
        //         };

        //         case (_) {
        //             Debug.trap("Should not reach with row = " # debug_show row # " and col = " # debug_show col);
        //         };
        //     }
        // );

        // bench;

        let b2 = Bench.Bench();
        bench.rows(["Array"]);
        bench.cols(["tabulate()", "tabulateVar()"]);

        bench.runner(
            func(row, col) = switch (row, col) {
                case ("Array", "tabulate()") {
                    for (i in Iter.range(0, limit / 32)) {
                        let arr = Array.tabulate<Nat>(32, func(i) = i);
                    };
                };
                case ("Array", "tabulateVar()") {
                    for (i in Iter.range(0, limit / 32)) {
                        let arr = Array.tabulateVar<Nat>(32, func(i) = i);
                    };
                };
                case (_) {
                    Debug.trap("Should not reach with row = " # debug_show row # " and col = " # debug_show col);
                };
            }
        );

        b2;
    };
};
