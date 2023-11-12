module {
    public type Cursor<T> = {
        val: () -> T;
        next: () -> ();
        hasNext: () -> Bool;

        prev: () -> ();
        hasPrev: () -> Bool;

        update: (T) -> ();
    };

    public type Ref<T> = {
        val: () -> T;
        next: () -> ();
        hasNext: () -> Bool;

        prev: () -> ();
        hasPrev: () -> Bool;

        update: (T) -> ();
    };
}