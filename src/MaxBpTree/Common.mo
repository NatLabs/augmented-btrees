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

    type UpdateLeafFieldsFn<K, V> = T.UpdateLeafFieldsFn<K, V>;
    type UpdateBranchFieldsFn<K, V> = T.UpdateBranchFieldsFn<K, V>;

    public func update_leaf_fields<K, V>(cmp_val: CmpFn<V>) : UpdateLeafFieldsFn<K, V> {

        func update_fields(fields : MaxField<K, V>, index : Nat, kv : (K, V)) {
            let ?curr_max = fields.max else {
                fields.max := ?{
                    var key = kv.0;
                    var val = kv.1;
                    var index = index;
                };

                return;
            };

            if (cmp_val(kv.1, curr_max.val) == #greater) {
                curr_max.key := kv.0;
                curr_max.val := kv.1;
                curr_max.index := index;
            };
        };
    };


    public func update_branch_fields<K, V>(cmp_val: CmpFn<V>) : UpdateBranchFieldsFn<K, V> {

        func update_fields(fields : MaxField<K, V>, index : Nat, node : Node<K, V>) {
            switch (node) {
                case (#leaf(node) or #branch(node) : InternalTypes.CommonNodeFields<K, V, MaxField<K, V>>) {
                    let ?curr_max = fields.max else {
                        fields.max := node.fields.max;
                        return;
                    };

                    let ?node_max = node.fields.max else Debug.trap("Branch.new: node.max is null");

                    if (cmp_val(node_max.val, curr_max.val) == #greater) {
                        fields.max := node.fields.max;
                    };
                };
            };
        };
    };
};
