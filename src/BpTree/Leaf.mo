import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Order "mo:base/Order";

import T "Types";
import InternalTypes "../internal/Types";
import ArrayMut "../internal/ArrayMut";
import InternalLeaf "../internal/Leaf";

import Utils "../internal/Utils";

module Leaf {
    type Order = Order.Order;
    public type Leaf<K, V> = T.Leaf<K, V>;
    type Node<K, V> = T.Node<K, V>;
    type BpTree<K, V> = T.BpTree<K, V>;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;

    public func new<K, V>(order : Nat, count : Nat, opt_kvs : ?[var ?(K, V)], gen_id : () -> Nat) : Leaf<K, V> {
        InternalLeaf.new(order, count, opt_kvs, gen_id, (), null);
    };

    public func split<K, V>(leaf : Leaf<K, V>, elem_index : Nat, elem : (K, V), gen_id : () -> Nat) : Leaf<K, V> {
        InternalLeaf.split(leaf, elem_index, elem, gen_id, (), null, null);
    };

    public func redistribute_keys<K, V>(leaf_node : Leaf<K, V>) {

        let ?parent = leaf_node.parent else return;

        var adj_node = leaf_node;
        if (parent.count > 1) {
            if (leaf_node.index != 0) {
                let ? #leaf(left_adj_node) = parent.children[leaf_node.index - 1] else Debug.trap("1. redistribute_leaf_keys: accessed a null value");
                adj_node := left_adj_node;
            };

            if (leaf_node.index != (parent.count - 1 : Nat)) {
                let ? #leaf(right_adj_node) = parent.children[leaf_node.index + 1] else Debug.trap("2. redistribute_leaf_keys: accessed a null value");
                if (right_adj_node.count > adj_node.count) {
                    adj_node := right_adj_node;
                };
            };
        };

        if (adj_node.index == leaf_node.index) return; // no adjacent node to distribute data to

        let sum_count = leaf_node.count + adj_node.count;
        let min_count_for_both_nodes = leaf_node.kvs.size();

        if (sum_count < min_count_for_both_nodes) return; // not enough entries to distribute

        let data_to_move = (sum_count / 2) - leaf_node.count : Nat;

        // distribute data between adjacent nodes
        if (adj_node.index < leaf_node.index) {
            // adj_node is before leaf_node
            // Debug.print("chose left node");
            var i = 0;
            ArrayMut.shift_by(leaf_node.kvs, 0, leaf_node.count, data_to_move);
            for (_ in Iter.range(0, data_to_move - 1)) {
                let val = ArrayMut.remove(adj_node.kvs, adj_node.count - i - 1 : Nat, adj_node.count);
                leaf_node.kvs[data_to_move - i - 1] := val;

                i += 1;
            };
        } else {
            // adj_node is after leaf_node
            // Debug.print("chose right node");

            var i = 0;
            for (_ in Iter.range(0, data_to_move - 1)) {
                let val = adj_node.kvs[i];
                ArrayMut.insert(leaf_node.kvs, leaf_node.count + i, val, leaf_node.count);

                i += 1;
            };

            ArrayMut.shift_by(adj_node.kvs, i, adj_node.count, -i);
        };

        adj_node.count -= data_to_move;
        leaf_node.count += data_to_move;

        // update parent keys
        if (adj_node.index < leaf_node.index) {
            // no need to worry about leaf_node.index - 1 being out of bounds because
            // the adj_node is before the leaf_node, meaning the leaf_node is not the first child
            let ?leaf_2nd_entry = leaf_node.kvs[0] else Debug.trap("3. redistribute_leaf_keys: accessed a null value");
            let leaf_node_key = leaf_2nd_entry.0;

            let key_index = leaf_node.index - 1 : Nat;
            parent.keys[key_index] := ?leaf_node_key;
        } else {
            // and vice versa
            let ?adj_2nd_entry = adj_node.kvs[0] else Debug.trap("4. redistribute_leaf_keys: accessed a null value");
            let adj_node_key = adj_2nd_entry.0;

            let key_index = adj_node.index - 1 : Nat;
            parent.keys[key_index] := ?adj_node_key;
        };

    };

    // merges two leaf nodes into the left node
    // !!! dont use
    public func merge<K, V>(left : Leaf<K, V>, right : Leaf<K, V>) {
        var i = 0;

        // merge right into left
        for (_ in Iter.range(0, right.count - 1)) {
            let val = right.kvs[i];
            ArrayMut.insert(left.kvs, left.count + i, val, left.count);

            i += 1;
        };

        left.count += right.count;

        // update leaf pointers
        left.next := right.next;
        switch (left.next) {
            case (?next) next.prev := ?left;
            case (_) {};
        };

    };

    public func remove<K, V>(leaf : Leaf<K, V>, index : Nat) : ?(K, V) {
        let removed = ArrayMut.remove(leaf.kvs, index, leaf.count);

        // leaf.count -= 1;
        removed;
    };

    public func equal<K, V>(a : Leaf<K, V>, b : Leaf<K, V>, cmp : CmpFn<K>) : Bool {
        for (i in Iter.range(0, a.kvs.size() - 1)) {
            let res = switch (a.kvs[i], b.kvs[i]) {
                case (?v1, ?v2) {
                    cmp(v1.0, v2.0) == #equal;
                };
                case (_) false;
            };

            if (not res) return false;
        };

        true;
    };

    public func toText<K, V>(self : Leaf<K, V>, key_to_text : (K) -> Text, val_to_text : (V) -> Text) : Text {
        var t = "leaf { index: " # debug_show self.index # ", count: " # debug_show self.count # ", kvs: ";

        t #= debug_show Array.map(
            Array.freeze(self.kvs),
            func(opt_kv : ?(K, V)) : Text {
                switch (opt_kv) {
                    case (?kv) "(" # key_to_text(kv.0) # ", " # val_to_text(kv.1) # ")";
                    case (_) "null";
                };
            },
        );

        t #= " }";

        t;
    };
};
