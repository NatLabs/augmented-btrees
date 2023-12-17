import Array "mo:base/Array";
import Option "mo:base/Option";

import BpTreeLeaf "../BpTree/Leaf";
import T "Types";
import BpTree "../BpTree";

import Utils "../internal/Utils";
import InternalTypes "../internal/Types";
import InternalLeaf "../internal/Leaf";
import InternalMethods "../internal/Methods";
import Common "Common";

module {
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

    public func new<K, V>(order : Nat, count : Nat, opt_kvs : ?[var ?(K, V)], gen_id : () -> Nat) : Leaf<K, V> {
        InternalLeaf.new<K, V, MaxField<K, V>>(order, count, opt_kvs, gen_id, Common.default_fields(), null);
    };

    public func split<K, V>(
        leaf : Leaf<K, V>,
        elem_index : Nat,
        elem : (K, V),
        gen_id : () -> Nat,
        reset_max_field : (MaxField<K, V>) -> (),
        update_leaf_fields: KvUpdateFieldFn<K, V>,
    ) : Leaf<K, V> {
        InternalLeaf.split<K, V, MaxField<K, V>>(leaf, elem_index, elem, gen_id, Common.default_fields(), ?reset_max_field, ?update_leaf_fields);
    };

};
