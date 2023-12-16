import Order "mo:base/Order";
import InternalTypes "../internal/Types";
import Internal "../internal";

module {
    type Order = Order.Order;

    public type CmpFn<K> = InternalTypes.CmpFn<K>;

    public type MaxField<K, V> = {
        var max : ?{
            var key : K;
            var val : V;
            var index : Nat;
        };
    };
    
    public type MaxBpTree<K, V> = InternalTypes.BpTree<K, V, MaxField<K, V>>;

    public type Node<K, V> = InternalTypes.Node<K, V, MaxField<K, V>>;

    public type Branch<K, V> = InternalTypes.Branch<K, V, MaxField<K, V>>;

    public type Leaf<K, V> = InternalTypes.Leaf<K, V, MaxField<K, V>>;

    public type CommonFields<K, V> = InternalTypes.CommonFields<K, V, MaxField<K, V>>;

    public type CommonNodeFields<K, V> = InternalTypes.CommonNodeFields<K, V, MaxField<K, V>>;

};
