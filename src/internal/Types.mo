import Order "mo:base/Order";

module {
    type Order = Order.Order;

    public type CmpFn<A> = (A, A) -> Order;
    public type MultiCmpFn<A, B> = (A, B) -> Order;

    public type SharedNodeFields<K, V> = {
        var count : Nat;
        var index : Nat;
        var parent : ?SharedNodeFields<K, V>;
    };

    public type SharedNode<K, V> = {
        #leaf : SharedNodeFields<K, V>;
        #branch : SharedNodeFields<K, V>;
    };
}