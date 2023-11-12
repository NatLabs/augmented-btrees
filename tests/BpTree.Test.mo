import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";

import { test; suite } "mo:test";
import Fuzz "mo:fuzz";
import Itertools "mo:itertools/Iter";

import { BpTree } "../src";

func print_node(node : BpTree.Node<Nat, Nat>) {
    switch (node) {
        case (#internal(n)) {
            Debug.print("internal node keys: " # debug_show n.keys);
            Debug.print("internal node children: " # debug_show n.children);

        };
        case (#leaf(n)) {
            Debug.print("leaf node: " # debug_show n.kvs);
        };
    };
};

let fuzz = Fuzz.Fuzz();

suite(
    "b-plus-tree",
    func() {
        // test(
        //     "insert",
        //     func() {
                
        //         let bptree = BpTree.newWithOrder<Nat, Nat>(32);

        //         let limit = 10_000;

        //         for (i in Iter.range(0, limit - 1)) {
        //             ignore BpTree.insert<Nat, Nat>(bptree, Nat.compare, i, i);
        //         };

        //         assert bptree.size == limit;
        //         // assert bptree.order == 32;

        //         var prev = -1;
        //         // Debug.print("depth: " # debug_show BpTree.depth(bptree));
        //         // Debug.print("leaf nodes: " # debug_show BpTree.toLeafNodes(bptree));
        //         // Debug.print("keys: " # debug_show BpTree.toNodeKeys(bptree));
        //         // Debug.print("entries: " # debug_show BpTree.toArray(bptree));
        //         for ((key, val) in BpTree.entries(bptree)) {
        //             if (prev + 1 != key) {
        //                 let leaf_node = BpTree.get_leaf_node(bptree, Nat.compare, key);
        //                 Debug.print("leaf nooooode:" # BpTree.LeafNode.toText(leaf_node, Nat.toText, Nat.toText));
        //                 Debug.print("mismatch: " # debug_show (prev, key));
        //                 assert false;
        //             };

        //             prev += 1;
        //         };
        //     },
        // );

        test(
            "insert random",
            func() {
                let limit = 1000;
                
                let bptree = BpTree.newWithOrder<Nat, Nat>(4);
                assert bptree.order == 4;

                for (i in Iter.range(0, limit - 1)) {
                    let key = fuzz.nat.randomRange(1, limit * 10); // range is big enough to avoid collisions
                    // Debug.print("insert " # debug_show key);

                    ignore BpTree.insert(bptree, Nat.compare, key, key);
                    // Debug.print("keys " # debug_show BpTree.toNodeKeys(bptree));
                    // Debug.print("leafs " # debug_show BpTree.toLeafNodes(bptree));

                };

                // assert BpTree.size(bptree) == limit;
                
                let ?min = BpTree.min<Nat, Nat>(bptree) else Debug.trap("unreachable");

                var prev = min.0;
                var i = 0;
                // Debug.print("entries " # debug_show BpTree.toArray(bptree));
                Debug.print("keys " # debug_show BpTree.toNodeKeys(bptree));
                Debug.print("leafs " # debug_show BpTree.toLeafNodes(bptree));

                for (curr in BpTree.keys(bptree)) {
                    
                    if (prev > curr) {
                        let leaf_node = BpTree.get_leaf_node(bptree, Nat.compare, curr);
                        Debug.print("leaf nooooode:" # BpTree.LeafNode.toText(leaf_node, Nat.toText, Nat.toText));
                        Debug.print("mismatch: " # debug_show (i, prev, curr));
                        Debug.trap("bptree is not sorted");
                        
                    };

                    prev := curr;
                    i+=1;
                };
            },
        );
    },
);
