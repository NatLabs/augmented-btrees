import BpTree "../BpTree";
import BpTreeTypes "../BpTree/Types";

module {

    public type Branch<K, V> = {
        var parent : ?Branch<K, V>;
        var index : Nat;
        var keys : [var ?K];
        var children : [var ?Node<K, V>];
        var count : Nat;
        var max : ?K;
    };

    public type Leaf<K, V> = {
        var parent : ?Branch<K, V>;
        var index : Nat;
        kvs : [var ?(K, V)];
        var count : Nat;
        var next : ?Leaf<K, V>;
        var max : ?K;
    };

    public type Node<K, V> = {
        #leaf : Leaf<K, V>;
        #branch : Branch<K, V>;
    };

    public type MaxBpTree<K, V> = {
        order : Nat;
        var root : Node<K, V>;
        var size : Nat;
    };

    
    public type SharedNodeFields<K, V> = {
        var parent : ?Branch<K, V>;
        var index : Nat;
        var count : Nat;
        var max : ?K;
    };

    public type SharedNode<K, V> = {
        #leaf : SharedNodeFields<K, V>;
        #branch : SharedNodeFields<K, V>;
    };
}
