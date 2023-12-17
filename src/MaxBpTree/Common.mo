import Array "mo:base/Array";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

import BpTreeLeaf "../BpTree/Leaf";
import T "Types";
import BpTree "../BpTree";

import Utils "../internal/Utils";
import InternalTypes "../internal/Types";
import InternalLeaf "../internal/Leaf";
import InternalMethods "../internal/Methods";

module Methods {
    public type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    type CommonFields<K, V> = T.CommonFields<K, V>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MultiCmpFn<A, B> = InternalTypes.MultiCmpFn<A, B>;
    type CmpFn<A> = InternalTypes.CmpFn<A>;
    type MaxField<K, V> = T.MaxField<K, V>;

    type KvUpdateFieldFn<K, V> = T.KvUpdateFieldFn<K, V>;
    type NodeUpdateFieldFn<K, V> = T.NodeUpdateFieldFn<K, V>;

    public func default_fields<K, V>() : MaxField<K, V> {
        return {
            var max_key = null;
            var max_val = null;
            var max_index = null;
        };
    };

    public func update_leaf_fields<K, V>(cmp_val : CmpFn<V>) : KvUpdateFieldFn<K, V> {

        func update_fields(fields : MaxField<K, V>, index : Nat, key : K, val : V) {
            let ?curr_max_val = fields.max_val else {
                fields.max_key := ?key;
                fields.max_val := ?val;
                fields.max_index := ?index;

                return;
            };

            if (cmp_val(val, curr_max_val) != #less) {
                fields.max_key := ?key;
                fields.max_val := ?val;
                fields.max_index := ?index;
            };
        };
    };

    public func update_branch_fields<K, V>(cmp_val : CmpFn<V>) : NodeUpdateFieldFn<K, V> {

        func update_fields(fields : MaxField<K, V>, index : Nat, node : Node<K, V>) {
            switch (node) {
                case (#leaf(node) or #branch(node) : InternalTypes.CommonNodeFields<K, V, MaxField<K, V>>) {
                    let ?curr_max_val = fields.max_val else {
                        fields.max_key := node.fields.max_key;
                        fields.max_val := node.fields.max_val;
                        fields.max_index := ?index;
                        return;
                    };

                    let ?node_max_val = node.fields.max_val else Debug.trap("Branch.new: node.max is null");

                    if (cmp_val(node_max_val, curr_max_val) != #less) {
                        fields.max_key := node.fields.max_key;
                        fields.max_val := node.fields.max_val;
                        fields.max_index := ?index;
                    };
                };
            };
        };
    };
};
