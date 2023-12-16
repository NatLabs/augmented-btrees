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

    type UpdateLeafFieldsFn<K, V, Extra> = InternalTypes.UpdateLeafFieldsFn<K, V, Extra>;

    public func new<K, V, Extra>(
        order : Nat, 
        count : Nat, 
        opt_kvs : ?[var ?(K, V)], 
        gen_id: () -> Nat, 
        default_fields: Extra,
        opt_update_fields: ?(UpdateLeafFieldsFn<K, V, Extra>)
    ) : Leaf<K, V, Extra> {
        let leaf_node : Leaf<K, V, Extra> = {
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

        let ?update_fields = opt_update_fields else return leaf_node;

        var i = 0;

        while ( i < count ) {
            let ?kv = leaf_node.kvs[i] else Debug.trap("Leaf.new: kv is null");
            update_fields(leaf_node.fields, i, kv);
            i += 1;
        };

        leaf_node;
    };

    public func split<K, V, Extra>(
        leaf : Leaf<K, V, Extra>, 
        elem_index : Nat, 
        elem : (K, V), 
        gen_id: () -> Nat, 
        default_fields: Extra,
        opt_reset_fields: ?((Extra) -> ()),
        opt_update_fields: ?UpdateLeafFieldsFn<K, V, Extra>,
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
        let right_node = Leaf.new(leaf.kvs.size(), right_cnt, ?right_kvs, gen_id, default_fields, opt_update_fields);

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

        let ?reset_fields = opt_reset_fields else return right_node;
        let ?update_fields = opt_update_fields else return right_node;

        var i = 0;
        reset_fields(leaf.fields);
        while ( i < leaf.count ) {
            let ?kv = leaf.kvs[i] else Debug.trap("Leaf.split: kv is null");
            update_fields(leaf.fields, i, kv);
            i += 1;
        };

        right_node;
    };
};