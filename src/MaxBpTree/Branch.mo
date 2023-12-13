import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Order "mo:base/Order";

import Itertools "mo:itertools/Iter";

import T "Types";
import InternalTypes "../internal/Types";
import Leaf "Leaf";
import Utils "../internal/Utils";
import ArrayMut "../internal/ArrayMut";
import InternalBranch "../internal/Branch";

module Branch {
    type Order = Order.Order;
    public type Branch<K, V> = T.Branch<K, V>;
    type Node<K, V> = T.Node<K, V>;
    type Leaf<K, V> = T.Leaf<K, V>;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MaxField<V> = T.MaxField<V>;
    
    public func new<K, V, >(
        order : Nat,
        opt_keys : ?[var ?K],
        opt_children : ?[var ?Node<K, V>],
        gen_id: () -> Nat,
        cmp: CmpFn<V>,
    ) : Branch<K, V> {
        func update_fields(fields: MaxField<V>, index: Nat, node: Node<K, V>) {
            switch (node) {
                case (#leaf(node) or #branch(node) : InternalTypes.CommonNodeFields<K, V, MaxField<V>>) {
                    let ?curr_max = fields.max else {
                        fields.max := node.fields.max;
                        return;
                    };

                    let ?node_max = node.fields.max else Debug.trap("Branch.new: node.max is null");

                    if (cmp(node_max.val, curr_max.val) == #greater){
                        fields.max := node.fields.max;
                    };
                };
            };
        };

        InternalBranch.new<K, V, MaxField<V>>(order, opt_keys, opt_children, gen_id, { var max = null }, ?update_fields);
    };

    public func update_median_key<K, V>(_parent: Branch<K, V>, index: Nat, new_key: K){
        var parent = _parent;
        var i = index;

        while (i == 0){
            i:= parent.index;
            let ?__parent = parent.parent else return; // occurs when key is the first key in the tree
            parent := __parent;
        };

        parent.keys[i - 1] := ?new_key;
    };

    // public func _split<K, V>(node : Branch<K, V>, child : Node<K, V>, child_index : Nat, first_child_key : K, gen_id : () -> Nat, new_branch: (Nat, ?[var ?Node<K, V>], () -> Nat) -> Branch<K, V>) : Branch<K, V> {
    //     let arr_len = node.count;
    //     let median = (arr_len / 2) + 1;

    //     let is_elem_added_to_right = child_index >= median;

    //     var median_key = ?first_child_key;

    //     var offset = if (is_elem_added_to_right) 0 else 1;
    //     var already_inserted = false;

    //     let right_keys = Array.init<?K>(node.keys.size(), null);

    //     let right_children = Utils.tabulate_var<Node<K, V>>(
    //         node.children.size(),
    //         node.count + 1 - median,
    //         func(i : Nat) : ?Node<K, V> {

    //             let j = i + median - offset : Nat;

    //             let child_node = if (j >= median and j == child_index and not already_inserted) {
    //                 offset += 1;
    //                 already_inserted := true;
    //                 if (i > 0) right_keys[i - 1] := ?first_child_key;
    //                 ?child;
    //             } else if (j >= arr_len) {
    //                 null;
    //             } else {
    //                 if (i == 0) {
    //                     median_key := node.keys[j - 1];
    //                 } else {
    //                     right_keys[i - 1] := node.keys[j - 1];
    //                 };
    //                 node.keys[j - 1] := null;
    //                 Utils.extract(node.children, j);
    //             };

    //             switch (child_node) {
    //                 case (?#branch(child)){
    //                     child.index := i;
    //                     node.subtree_size -= child.subtree_size;
    //                 };
    //                 case (?#leaf(child)){
    //                     child.index := i;
    //                     node.subtree_size -= child.count;
    //                 };
    //                 case (_) {};
    //             };

    //             child_node;
    //         },
    //     );

    //     var j = median - 1 : Nat;

    //     while (j > child_index) {
    //         if (j >= 2) {
    //             node.keys[j - 1] := node.keys[j - 2];
    //         };

    //         node.children[j] := node.children[j - 1];

    //         switch (node.children[j]) {
    //             case (? #branch(node) or ? #leaf(node) : ?CommonNodeFields<K, V>) {
    //                 node.index := j;
    //             };
    //             case (_) {};
    //         };

    //         j -= 1;
    //     };

    //     if (j == child_index) {
    //         if (j > 0) {
    //             node.keys[j - 1] := ?first_child_key;
    //             node.children[j] := ?child;
    //         } else {
    //             update_median_key(node, 0, first_child_key);
    //             node.children[0] := ?child;
    //         };
    //     };

    //     node.count := median;
    //     let right_cnt = node.children.size() + 1 - median : Nat;

    //     let right_node = switch (node.children[0]) {
    //         case (? #leaf(_)) new_branch(node.children.size(), ?right_children, gen_id);
    //         case (? #branch(_)) {
    //             Branch.newWithKeys<K, V>(right_keys, right_children, gen_id);
    //             // Branch new fails to update the median key to its correct position so we do it manually
    //         };
    //         case (_) Debug.trap("right_node: accessed a null value");
    //     };

    //     right_node.index := node.index + 1;

    //     right_node.count := right_cnt;
    //     right_node.parent := node.parent;

    //     // store the first key of the right node at the end of the keys in left node
    //     // no need to delete as the value will get overwritten because it exceeds the count position
    //     right_node.keys[right_node.keys.size() - 1] := median_key;

    //     right_node;
    // };

};