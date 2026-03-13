import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imad_flutter/imad_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async => Directory.systemTemp.path,
        );

    // Mock audio_service
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_service.client.methods'),
          (MethodCall methodCall) async => null,
        );

    // Mock audio_service handler
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_service.handler.methods'),
          (MethodCall methodCall) async => null,
        );
  });

  late BookmarkRepository repository;

  setUpAll(() async {
    await setupMushafWithHive();
    await MushafLibrary.initialize(
      databaseService: mushafGetIt<DatabaseService>(),
      bookmarkDao: mushafGetIt<BookmarkDao>(),
      readingHistoryDao: mushafGetIt<ReadingHistoryDao>(),
      searchHistoryDao: mushafGetIt<SearchHistoryDao>(),
    );
    repository = MushafLibrary.getBookmarkRepository();
  });

  setUp(() async {
    await repository.deleteAllBookmarks();
  });

  test('Add bookmark should store bookmark', () async {
    await repository.addBookmark(
      chapterNumber: 1,
      verseNumber: 1,
      pageNumber: 1,
    );
    final bookmarks = await repository.getAllBookmarks();
    expect(bookmarks.length, 1);
    expect(bookmarks.first.pageNumber, 1);
  });

  test('Delete bookmark should remove bookmark', () async {
    final bookmark = await repository.addBookmark(
      chapterNumber: 1,
      verseNumber: 2,
      pageNumber: 5,
    );
    await repository.deleteBookmark(bookmark.id);
    final bookmarks = await repository.getAllBookmarks();
    expect(bookmarks.isEmpty, true);
  });

  test('isVerseBookmarked should return true if bookmarked', () async {
    await repository.addBookmark(
      chapterNumber: 2,
      verseNumber: 10,
      pageNumber: 30,
    );
    final result = await repository.isVerseBookmarked(2, 10);
    expect(result, true);
  });
}
