import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Order "mo:base/Order";

import Itertools "mo:itertools/Iter";

// import T "Types";
import InternalTypes "Types";
import InternalMethods "Methods";
// import Leaf "Leaf";
import Utils "Utils";
import ArrayMut "ArrayMut";

module Leaf {
    type Order = Order.Order;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type CommonNodeFields<K, V, Extra> = InternalTypes.CommonNodeFields<K, V, Extra>;

    type BpTree<K, V, Extra> = InternalTypes.BpTree<K, V, Extra>;
    type Node<K, V, Extra> = InternalTypes.Node<K, V, Extra>;
    type Leaf<K, V, Extra> = InternalTypes.Leaf<K, V, Extra>;
    type Branch<K, V, Extra> = InternalTypes.Branch<K, V, Extra>;

    public func new<K, V, Extra>(order : Nat, count : Nat, opt_kvs : ?[var ?(K, V)], gen_id: () -> Nat, default_fields: Extra) : Leaf<K, V, Extra> {
        return {
            id = gen_id();
            var parent = null;
            var index = 0;
            kvs = switch (opt_kvs) {
                case (?kvs) kvs;
                case (_) Array.init<?(K, V)>(order, null);
            };
            var count = count;
            var next = null;
            var prev = null;
            fields = default_fields;
        };
    };

    public func split<K, V, Extra>(
        leaf : Leaf<K, V, Extra>, 
        elem_index : Nat, 
        elem : (K, V), 
        gen_id: () -> Nat, 
        new_leaf: (order : Nat, count : Nat, opt_kvs : ?[var ?(K, V)], gen_id: () -> Nat) -> Leaf<K, V, Extra>
    ) : Leaf<K, V, Extra> {

        let arr_len = leaf.count;
        let median = (arr_len / 2) + 1;

        let is_elem_added_to_right = elem_index >= median;

        // if elem is added to the left
        // this variable allows us to retrieve the last element on the left
        // that gets shifted by the inserted elemeent
        var offset = if (is_elem_added_to_right) 0 else 1;

        var already_inserted = false;
        let right_kvs = Utils.tabulate_var<(K, V)>(
            leaf.kvs.size(),
            leaf.count + 1 - median,
            func(i : Nat) : ?(K, V) {

                let j = i + median - offset : Nat;

                if (j >= median and j == elem_index and not already_inserted) {
                    offset += 1;
                    already_inserted := true;
                    ?elem;
                } else if (j >= arr_len) {
                    null;
                } else {
                    Utils.extract(leaf.kvs, j);
                };
            },
        );

        var j = median - 1 : Nat;

        while (j > elem_index) {
            leaf.kvs[j] := leaf.kvs[j - 1];
            j -= 1;
        };

        if (j == elem_index) {
            leaf.kvs[j] := ?elem;
        };

        leaf.count := median;
        let right_cnt = arr_len + 1 - median : Nat;
        let right_node = new_leaf(leaf.kvs.size(), right_cnt, ?right_kvs, gen_id);

        right_node.index := leaf.index + 1;
        right_node.parent := leaf.parent;

        // update leaf pointers
        right_node.next := leaf.next;
        leaf.next := ?right_node;

        right_node.prev := ?leaf;

        switch (right_node.next) {
            case (?next) next.prev := ?right_node;
            case (_) {};
        };

        right_node;
    };
};