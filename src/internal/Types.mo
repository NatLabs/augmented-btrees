import Order "mo:base/Order";
import Result "mo:base/Result";

module {
    type Order = Order.Order;
    type Result<T, E> = Result.Result<T, E>;

    public type CmpFn<A> = (A, A) -> Order;
    public type MultiCmpFn<A, B> = (A, B) -> Order;

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