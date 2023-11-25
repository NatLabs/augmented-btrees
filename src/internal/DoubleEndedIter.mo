import Option "mo:base/Option";

module {
    /// A Double Ended Iterator that can be reversed.
    public type DoubleEndedIter<T> = {
        /// Returns the next element in the iterator.
        next: () -> ?T;

        /// Returns the element at the end of the iterator
        nextFromEnd: () -> ?T;

        /// Returns a new iterator that is the reverse of this one.
        rev: () -> DoubleEndedIter<T>;
    };

    public func new<A>(next: () -> ?A, nextFromEnd: () -> ?A): DoubleEndedIter<A> {
        let iter = {
            next = next;
            nextFromEnd = nextFromEnd;
            rev = func() : DoubleEndedIter<A> {
                {
                    next = nextFromEnd;
                    nextFromEnd = next;
                    rev = func() = iter;
                };
            };
        };
    };

    public func map<A, B>(deiter: DoubleEndedIter<A>, f: (A) -> B): DoubleEndedIter<B> {
        func next() : ?B {
            Option.map(deiter.next(), f);
        };

        func nextFromEnd() : ?B {
            Option.map(deiter.nextFromEnd(), f);
        };

        return new(next, nextFromEnd);
    };
};