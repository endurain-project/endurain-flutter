import 'dart:collection';

/// An unmodifiable list that is a fixed-length prefix of a shared, append-only
/// backing store.
///
/// [appended] returns a longer list in amortised O(items added): when this is
/// the longest view of its store the items are pushed onto the shared backing
/// list, and every older view keeps seeing exactly its own prefix. Only when an
/// older view is extended (a fork) are the elements copied. This is what lets a
/// long recording grow without re-copying the whole track for every point
/// batch, while each state still exposes an immutable snapshot.
///
/// Every call to [appended] returns a new instance, so identity changes exactly
/// when the content does.
final class AppendOnlyList<E> extends ListBase<E> {
  AppendOnlyList() : this._(<E>[], 0);

  AppendOnlyList._(this._store, this._length);

  /// Copies [items] into a new store.
  factory AppendOnlyList.of(Iterable<E> items) {
    final store = List<E>.of(items);
    return AppendOnlyList._(store, store.length);
  }

  final List<E> _store;
  final int _length;

  /// A list holding these elements followed by [items]; this list is unchanged.
  AppendOnlyList<E> appended(Iterable<E> items) {
    final store = _store.length == _length
        ? _store
        : List<E>.of(_store.getRange(0, _length), growable: true);
    store.addAll(items);
    return AppendOnlyList._(store, store.length);
  }

  @override
  int get length => _length;

  @override
  set length(int newLength) => throw UnsupportedError(
    'Cannot change the length of an unmodifiable list',
  );

  @override
  E operator [](int index) {
    RangeError.checkValidIndex(index, this);
    return _store[index];
  }

  @override
  void operator []=(int index, E value) =>
      throw UnsupportedError('Cannot modify an unmodifiable list');
}
