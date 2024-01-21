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
        bench.name("Comparing B+Tree and Max B+Tree");
        bench.description("Benchmarking the performance with 10k entries");

        bench.rows(["B+Tree", "Max B+Tree"]);
        bench.cols(["getByRank()", "getRank()", "getFloor()", "getCeiling()", "removeMin()", "removeMax()"]);

        let limit = 10_000;
        
        let {nhash} = Map;
        let bptree = BpTree.new<Nat, Nat>(?32);
        let max_bp_tree = MaxBpTree.new<Nat, Nat>(?32);

        let entries = Buffer.Buffer<(Nat, Nat)>(limit);

        for (i in Iter.range(0, limit - 1)) {
            let key = fuzz.nat.randomRange(1, limit ** 3);
            let val = fuzz.nat.randomRange(1, limit ** 3);

            entries.add((key, val));
            ignore BpTree.insert(bptree, Nat.compare, key, val);
            ignore MaxBpTree.insert(max_bp_tree, Nat.compare, Nat.compare, key, val);
        };

        let sorted = Buffer.clone(entries);
        sorted.sort(func(a, b) = Nat.compare(a.0, b.0));

        bench.runner(
            func(row, col) = switch (row, col) {
                case ("B+Tree", "getByRank()") {
                    for (i in Iter.range(0, limit - 1)) {
                        ignore BpTree.getByRank(bptree, i);
                    };
                };
                case ("B+Tree", "getRank()") {
                    for ((key, val) in entries.vals()) {
                        ignore BpTree.getRank(bptree, Nat.compare, key);
                    };
                };
                case ("B+Tree", "getFloor()") {
                    for (kv in entries.vals()) {
                        ignore BpTree.getFloor(bptree, Nat.compare, kv.0);
                    };
                };
                case ("B+Tree", "getCeiling()") {
                    for (kv in entries.vals()) { 
                        ignore BpTree.getFloor(bptree, Nat.compare, kv.0);
                     };
                };
                case ("B+Tree", "removeMin()") {
                    while (BpTree.size(bptree) > 0){
                        ignore BpTree.removeMin(bptree, Nat.compare);
                    };
                };
                case ("B+Tree", "removeMax()") {
                    while (BpTree.size(bptree) > 0){
                        ignore BpTree.removeMax(bptree, Nat.compare);
                    };
                };

                case ("Max B+Tree", "getByRank()") {
                    for (i in Iter.range(0, limit - 1)) {
                        ignore MaxBpTree.getByRank(max_bp_tree, i);
                    };
                };
                case ("Max B+Tree", "getRank()") {
                    for ((key, val) in entries.vals()) {
                        ignore MaxBpTree.getRank(max_bp_tree, Nat.compare, key);
                    };
                };
                case ("Max B+Tree", "getFloor()") {
                    for (kv in entries.vals()) {
                        ignore MaxBpTree.getFloor(max_bp_tree, Nat.compare, kv.0);
                    };
                };
                case ("Max B+Tree", "getCeiling()") {
                    for (kv in entries.vals()) { 
                        ignore MaxBpTree.getFloor(max_bp_tree, Nat.compare, kv.0);
                     };
                };
                case ("Max B+Tree", "removeMin()") {
                    while (MaxBpTree.size(max_bp_tree) > 0){
                        ignore MaxBpTree.removeMin(max_bp_tree, Nat.compare, Nat.compare);
                    };
                };
                case ("Max B+Tree", "removeMax()") {
                    while (MaxBpTree.size(max_bp_tree) > 0){
                        ignore MaxBpTree.removeMax(max_bp_tree, Nat.compare, Nat.compare);
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
