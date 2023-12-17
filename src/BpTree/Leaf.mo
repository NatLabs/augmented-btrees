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
        InternalLeaf.redistribute_keys(leaf_node, null, null, null);
    };

    // merges two leaf nodes into the left node
    public func merge<K, V>(left : Leaf<K, V>, right : Leaf<K, V>) {
        InternalLeaf.merge(left, right, null, null);
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
