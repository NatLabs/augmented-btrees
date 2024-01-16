import Array "mo:base/Array";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

import BpTreeLeaf "../BpTree/Leaf";
import T "Types";
import BpTree "../BpTree";

import Utils "../internal/Utils";
import InternalTypes "../internal/Types";

module Methods {
    public type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    public type Node<K, V> = T.Node<K, V>;
    public type Leaf<K, V> = T.Leaf<K, V>;
    public type Branch<K, V> = T.Branch<K, V>;
    type CommonFields<K, V> = T.CommonFields<K, V>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MultiCmpFn<A, B> = InternalTypes.MultiCmpFn<A, B>;
    type CmpFn<A> = InternalTypes.CmpFn<A>;

    type UpdateLeafMaxFn<K, V> = T.UpdateLeafMaxFn<K, V>;
    type UpdateBranchMaxFn<K, V> = T.UpdateBranchMaxFn<K, V>;

    public func update_leaf_fields<K, V>(cmp_val : CmpFn<V>) : UpdateLeafMaxFn<K, V> {

        func update_fields(leaf : CommonFields<K, V>, index : Nat, key : K, val : V) {
            let ?max = leaf.max else {
                leaf.max := ?(key, val, index);
                return;
            };

            let max_key = max.0;
            let max_val = max.1;

            if (cmp_val(val, max_val) != #less) {
                leaf.max := ?(key, val, index);
            };
        };
    };

    public func update_branch_fields<K, V>(cmp_val : CmpFn<V>) : UpdateBranchMaxFn<K, V> {

        func update_fields(branch : Branch<K, V>, index : Nat, child_node : Node<K, V>) {
            switch (child_node) {
                case (#leaf(child) or #branch(child) : CommonNodeFields<K, V>) {
                    let ?child_max = child.max else Debug.trap("Branch.new: child.max is null");

                    let ?max = branch.max else {
                        branch.max := child.max;
                        return;
                    };

                    let branch_max_key = max.0;
                    let branch_max_val = max.1;

                    let child_max_val = child_max.1;

                    if (cmp_val(child_max_val, branch_max_val) != #less) {
                        branch.max := child.max;
                    };
                };
            };
        };
    };
};
