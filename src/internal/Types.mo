import Order "mo:base@0.14.13/Order";
import Result "mo:base@0.14.13/Result";

module {
    type Order = Order.Order;
    type Result<T, E> = Result.Result<T, E>;

    public type CmpFn<A> = (A, A) -> Int8;
    public type MultiCmpFn<A, B> = (A, B) -> Int8;

}