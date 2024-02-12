import Order "mo:base/Order";
import Result "mo:base/Result";

module {
    type Order = Order.Order;
    type Result<T, E> = Result.Result<T, E>;

    public type CmpFn<A> = (A, A) -> Order;
    public type MultiCmpFn<A, B> = (A, B) -> Order;

    public type Int8CmpFn<A> = (A, A) -> Int8;
    public type Int8MultiCmpFn<A, B> = (A, B) -> Int8;

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