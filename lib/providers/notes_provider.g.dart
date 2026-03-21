// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notesNotifierHash() => r'd90820a477bb209d64b8d15fcb57ff89bd77715d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$NotesNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Note>> {
  late final String? category;
  late final String sort;

  FutureOr<List<Note>> build({
    String? category,
    String sort = 'new',
  });
}

/// See also [NotesNotifier].
@ProviderFor(NotesNotifier)
const notesNotifierProvider = NotesNotifierFamily();

/// See also [NotesNotifier].
class NotesNotifierFamily extends Family<AsyncValue<List<Note>>> {
  /// See also [NotesNotifier].
  const NotesNotifierFamily();

  /// See also [NotesNotifier].
  NotesNotifierProvider call({
    String? category,
    String sort = 'new',
  }) {
    return NotesNotifierProvider(
      category: category,
      sort: sort,
    );
  }

  @override
  NotesNotifierProvider getProviderOverride(
    covariant NotesNotifierProvider provider,
  ) {
    return call(
      category: provider.category,
      sort: provider.sort,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'notesNotifierProvider';
}

/// See also [NotesNotifier].
class NotesNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<NotesNotifier, List<Note>> {
  /// See also [NotesNotifier].
  NotesNotifierProvider({
    String? category,
    String sort = 'new',
  }) : this._internal(
          () => NotesNotifier()
            ..category = category
            ..sort = sort,
          from: notesNotifierProvider,
          name: r'notesNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$notesNotifierHash,
          dependencies: NotesNotifierFamily._dependencies,
          allTransitiveDependencies:
              NotesNotifierFamily._allTransitiveDependencies,
          category: category,
          sort: sort,
        );

  NotesNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.category,
    required this.sort,
  }) : super.internal();

  final String? category;
  final String sort;

  @override
  FutureOr<List<Note>> runNotifierBuild(
    covariant NotesNotifier notifier,
  ) {
    return notifier.build(
      category: category,
      sort: sort,
    );
  }

  @override
  Override overrideWith(NotesNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: NotesNotifierProvider._internal(
        () => create()
          ..category = category
          ..sort = sort,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        category: category,
        sort: sort,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<NotesNotifier, List<Note>>
      createElement() {
    return _NotesNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotesNotifierProvider &&
        other.category == category &&
        other.sort == sort;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);
    hash = _SystemHash.combine(hash, sort.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NotesNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Note>> {
  /// The parameter `category` of this provider.
  String? get category;

  /// The parameter `sort` of this provider.
  String get sort;
}

class _NotesNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<NotesNotifier, List<Note>>
    with NotesNotifierRef {
  _NotesNotifierProviderElement(super.provider);

  @override
  String? get category => (origin as NotesNotifierProvider).category;
  @override
  String get sort => (origin as NotesNotifierProvider).sort;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
