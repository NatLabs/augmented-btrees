import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import RbTree "mo:base/RBTree";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";

import Bench "mo:bench";
import Fuzz "mo:fuzz";
import BTree "mo:stableheapbtreemap/BTree";

import { BpTree }  "../src";

module {

    public func init() : Bench.Bench {
        let fuzz = Fuzz.Fuzz();

        let bench = Bench.Bench();
        bench.name("Comparing RBTree, BTree and B+Tree (BpTree)");
        bench.description("Benchmarking the performance with 10k entries");

        bench.rows(["RBTree", "BTree", "B+Tree"]);
        bench.cols(["insert()", "get()",  "delete()"]);

        let limit = 512;

        let btree = BTree.init<Nat, Nat>(?32);
        let bptree = BpTree.newWithOrder<Nat, Nat>(32);
        let rbtree = RbTree.RBTree<Nat, Nat>(Nat.compare);

        let insert_values = Buffer.Buffer<Nat>(limit);

        for (i in Iter.range(0, limit - 1)){
            insert_values.add(fuzz.nat.randomRange(1, limit));
        };

        bench.runner(
            func(row, col) = switch (row, col) {

                case ("RBTree", "insert()") {
                    var i = 0;

                    for (val in insert_values.vals()){
                        rbtree.put(i, val);
                        i+=1;
                    }
                };
                case("RBTree", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        ignore rbtree.get(i);
                    };
                };
                case("RBTree", "delete()") {
                    for (i in Iter.range(0, limit - 1)) {
                        rbtree.delete(i);
                    };
                };

                case ("BTree", "insert()") {
                    var i = 0;

                    for (val in insert_values.vals()){
                        ignore BTree.insert(btree, Nat.compare, i, val);
                        i+=1;
                    }
                };
                case("BTree", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        ignore BTree.get(btree, Nat.compare, i);
                    };
                };
                case ("BTree", "delete()") {
                    for (i in Iter.range(0, limit - 1)) {
                        ignore BTree.delete(btree, Nat.compare, i);
                    };
                };

                case ("B+Tree", "insert()") {
                    var i = 0;

                    for (val in insert_values.vals()){
                        ignore BpTree.insert(bptree, Nat.compare, i, val);
                        i+=1;
                    }
                };
                case("B+Tree", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        ignore BTree.get(btree, Nat.compare, i);
                    };
                };
                case ("B+Tree", "delete()") {
                    // for (i in Iter.range(0, limit - 1)) {
                    //     ignore BTree.delete(btree, Nat.compare, i);
                    // };
                };
                case (_) {
                    Debug.trap("Should not reach with row = " # debug_show row # " and col = " # debug_show col);
                };
            }
        );

        bench;
    };
};
