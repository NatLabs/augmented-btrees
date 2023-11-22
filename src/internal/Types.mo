import Order "mo:base/Order";
import Result "mo:base/Result";

module {
    type Order = Order.Order;
    type Result<T, E> = Result.Result<T, E>;

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