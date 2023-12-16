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

import Common "Common";

module Branch {
    type Order = Order.Order;
    public type Branch<K, V> = T.Branch<K, V>;
    type Node<K, V> = T.Node<K, V>;
    type Leaf<K, V> = T.Leaf<K, V>;
    type CmpFn<K> = InternalTypes.CmpFn<K>;
    type CommonNodeFields<K, V> = T.CommonNodeFields<K, V>;
    type MaxField<K, V> = T.MaxField<K, V>;
    type MaxBpTree<K, V> = T.MaxBpTree<K, V>;
    type UpdateBranchFieldsFn<K, V> = T.UpdateBranchFieldsFn<K, V>;

    public func new<K, V>(
        max_bptree : MaxBpTree<K, V>,
        opt_keys : ?[var ?K],
        opt_children : ?[var ?Node<K, V>],
        gen_id: () -> Nat,
        update_branch_fields: UpdateBranchFieldsFn<K, V>,
    ) : Branch<K, V> {
        InternalBranch.new<K, V, MaxField<K, V>>(max_bptree.order, opt_keys, opt_children, gen_id, { var max = null }, ?update_branch_fields);
    };

    public func split<K, V>(
        node : Branch<K, V>, 
        child : Node<K, V>, 
        child_index : Nat, 
        first_child_key : K, 
        gen_id : () -> Nat, 
        reset_max_field : (MaxField<K, V>) -> (),
        update_branch_fields: UpdateBranchFieldsFn<K, V>,
    ) : Branch<K, V> {
        InternalBranch.split<K, V, MaxField<K, V>>(node, child, child_index, first_child_key, gen_id, { var max = null }, ?reset_max_field, ?update_branch_fields);
    };

};
