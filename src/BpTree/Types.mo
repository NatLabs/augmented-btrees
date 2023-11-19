import Order "mo:base/Order";

module {
    type Order = Order.Order;

    public type BpTree<K, V> = {
        order : Nat;
        var root : Node<K, V>;
        var size : Nat;
    };

    public type Node<K, V> = {
        #leaf : Leaf<K, V>;
        #branch : Branch<K, V>;
    };

    public type Branch<K, V> = {
        var parent : ?Branch<K, V>;
        var index : Nat;
        var keys : [var ?K];
        var children : [var ?Node<K, V>];
        var count : Nat;
    };

    public type Leaf<K, V> = {
        var parent : ?Branch<K, V>;
        var index : Nat;
        kvs : [var ?(K, V)];
        var count : Nat;
        var next : ?Leaf<K, V>;
    };

    public type SharedNodeFields<K, V> = {
        var count : Nat;
        var index : Nat;
        var parent : ?Branch<K, V>;
    };

    public type SharedNode<K, V> = {
        #leaf : SharedNodeFields<K, V>;
        #branch : SharedNodeFields<K, V>;
    };

}