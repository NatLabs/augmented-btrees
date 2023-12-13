import Order "mo:base/Order";
import InternalTypes "../internal/Types";
import Internal "../internal";

module {
    type Order = Order.Order;

    public type CmpFn<K> = InternalTypes.CmpFn<K>;

    public type MaxField<V> = {
        var max : ?{
            var val : V;
            var index : Nat;
        };
    };
    
    public type MaxBpTree<K, V> = InternalTypes.BpTree<K, V, MaxField<V>>;

    public type Node<K, V> = InternalTypes.Node<K, V, MaxField<V>>;

    public type Branch<K, V> = InternalTypes.Branch<K, V, MaxField<V>>;

    public type Leaf<K, V> = InternalTypes.Leaf<K, V, MaxField<V>>;

    public type CommonFields<K, V> = InternalTypes.CommonFields<K, V, MaxField<V>>;

    public type CommonNodeFields<K, V> = InternalTypes.CommonNodeFields<K, V, MaxField<V>>;

};
