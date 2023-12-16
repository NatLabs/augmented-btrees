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
    type MaxField<K, V> = T.MaxField<K, V>;
    type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    
    public func new<K, V, >(
        max_bptree: MaxBpTree<K, V>,
        opt_keys : ?[var ?K],
        opt_children : ?[var ?Node<K, V>],
        cmp: CmpFn<V>,
    ) : Branch<K, V> {
        func update_fields(fields: MaxField<K, V>, index: Nat, node: Node<K, V>) {
            switch (node) {
                case (#leaf(node) or #branch(node) : InternalTypes.CommonNodeFields<K, V, MaxField<K, V>>) {
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

        InternalBranch.new<K, V, MaxField<K, V>>(max_bptree, opt_keys, opt_children, { var max = null }, ?update_fields);
    };

    public func split<K, V>(node : Branch<K, V>, child : Node<K, V>, child_index : Nat, first_child_key : K, max_bp_tree: MaxBpTree<K, V>, cmp: CmpFn<V>) : Branch<K, V> {

        func new_branch(
            max_bptree: MaxBpTree<K, V>,
            opt_keys : ?[var ?K],
            opt_children : ?[var ?Node<K, V>],
        ) : Branch<K, V> {
            Branch.new<K, V>(max_bptree, opt_keys, opt_children, cmp);
        };

        InternalBranch.split<K, V, MaxField<K, V>>(node, child, child_index, first_child_key, max_bp_tree, new_branch);
    };

};