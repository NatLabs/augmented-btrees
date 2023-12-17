import Order "mo:base/Order";
import Result "mo:base/Result";

module {
    type Order = Order.Order;
    type Result<T, E> = Result.Result<T, E>;

    public type CmpFn<A> = (A, A) -> Order;
    public type MultiCmpFn<A, B> = (A, B) -> Order;
    public type KvUpdateFieldFn<K, V, Extra> = (Extra, Nat, K, V) -> ();
    public type NodeUpdateFieldFn<K, V, Extra> = (Extra, Nat, Node<K, V, Extra>) -> ();

    public type BpTree<K, V, Extra> = {
        order : Nat;
        var root : Node<K, V, Extra>;
        var size : Nat;
        var next_id : Nat;
    };

    public type Node<K, V, Extra> = {
        #leaf : Leaf<K, V, Extra>;
        #branch : Branch<K, V, Extra>;
    };

    public type Nodeify<A, B> = {
        #leaf : A;
        #branch : B;
    };

    public type Branch<K, V, Extra> = {
        id : Nat;
        var parent : ?Branch<K, V, Extra>;
        var index : Nat;
        var keys : [var ?K];
        var children : [var ?Node<K, V, Extra>];
        var count : Nat;
        var subtree_size : Nat;

        // Additional field for the branch node.
        fields : Extra;
    };

    public type Leaf<K, V, Extra> = {
        id : Nat;
        var parent : ?Branch<K, V, Extra>;
        var index : Nat;
        kvs : [var ?(K, V)];
        var count : Nat;
        var next : ?Leaf<K, V, Extra>;
        var prev : ?Leaf<K, V, Extra>;
        
        // Additional field for the leaf node.
        fields : Extra;
    };

    public type CommonFields<K, V, Extra> = Leaf<K, V, Extra> or Branch<K, V, Extra>;

    public type CommonNodeFields<K, V, Extra> = {
        #leaf : CommonFields<K, V, Extra>;
        #branch : CommonFields<K, V, Extra>;
    };

    type CursorError = {
        #IndexOutOfBounds;
    };
    
    public type Cursor<K, V> = {
        key: () -> ?K;
        value: () -> ?V;
        current: () -> ?(K, V);

        advance: () -> Result<(), CursorError>;
        moveBack: () -> Result<(), CursorError>;

        peekNext: () -> ?(K, V);
        peekBack: () -> ?(K, V);

        update: (V) -> Result<(), CursorError>;
        remove: () -> Result<(), CursorError>;
    };
}