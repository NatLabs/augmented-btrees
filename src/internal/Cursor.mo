import Result "mo:base/Result";

module {
    type Result<T, E> = Result.Result<T, E>;

    /// The cursor interface allows you to iterate over a collection.
    ///
    /// The cursor is always positioned at a key/value pair. The cursor
    /// is initially positioned before the first key/value pair. You must
    /// call `advance` or `moveBack` to position the cursor on a key/value
    
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