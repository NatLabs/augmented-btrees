import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import TrieSet "mo:base/TrieSet";

import { test; suite } "mo:test";
import Fuzz "mo:fuzz";
import Itertools "mo:itertools/Iter";

import { BpTree } "../src";

func print_node(node : BpTree.Node<Nat, Nat>) {
    switch (node) {
        case (#branch(n)) {
            Debug.print("branch keys: " # debug_show n.keys);
            Debug.print("branch children: " # debug_show n.children);

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
        test(
            "insert",
            func() {
                
                let bptree = BpTree.newWithOrder<Nat, Nat>(32);

                let limit = 10_000;

                let data = Buffer.Buffer<Nat>(limit);

                for (i in Iter.range(0, limit - 1)) {
                    ignore BpTree.insert(bptree, Nat.compare, i, i);
                    data.add(i);
                };

                let unique = Buffer.Buffer<Nat>(limit);
                let unique_iter = Itertools.unique<Nat>(data.vals(), Nat32.fromNat, Nat.equal);

                for (n in unique_iter) {
                    unique.add(n);
                };

                assert BpTree.size(bptree) == unique.size();

                let keys_iter = BpTree.keys(bptree);
                let data_iter = unique.vals();

                let zipped = Itertools.zip(keys_iter, data_iter);

                for ((i, (a, b)) in Itertools.enumerate(zipped)) {
                    if (a != b) {
                        let leaf_node = BpTree.get_leaf_node(bptree, Nat.compare, a);
                        Debug.print("leaf nooooode:" # BpTree.Leaf.toText(leaf_node, Nat.toText, Nat.toText));
                        Debug.print("mismatch: " # debug_show (a, b) # " at index " # debug_show i);
                        assert false;
                    };
                };
            },
        );

        test(
            "insert random",
            func() {
                let limit = 1_000;
                
                let bptree = BpTree.newWithOrder<Nat, Nat>(4);
                assert bptree.order == 4;

                 let data = Buffer.Buffer<Nat>(limit);

                for (i in Iter.range(0, limit - 1)) {
                    ignore BpTree.insert(bptree, Nat.compare, i, i);
                    data.add(i);
                };

                let unique = Buffer.Buffer<Nat>(limit);
                let unique_iter = Itertools.unique<Nat>(data.vals(), Nat32.fromNat, Nat.equal);

                for (n in unique_iter) {
                    unique.add(n);
                };

                assert BpTree.size(bptree) == unique.size();

                let keys_iter = BpTree.keys(bptree);
                let data_iter = unique.vals();

                let zipped = Itertools.zip(keys_iter, data_iter);


                for ((i, (a, b)) in Itertools.enumerate(zipped)) {
                    if (a != b) {
                        let leaf_node = BpTree.get_leaf_node(bptree, Nat.compare, a);
                        Debug.print("leaf node:" # BpTree.Leaf.toText(leaf_node, Nat.toText, Nat.toText));
                        Debug.print("mismatch: " # debug_show (a, b) # " at index " # debug_show i);
                        assert false;
                    };
                };
            },
        );
    },
);
