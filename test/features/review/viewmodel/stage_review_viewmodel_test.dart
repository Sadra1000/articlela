import 'package:flutter_test/flutter_test.dart';

import 'package:articlela/core/domain/entities/article_entity.dart';
import 'package:articlela/features/review/presentation/viewmodel/stage_review_viewmodel.dart';
import 'package:articlela/features/search_results/domain/usecases/export_articles_usecase.dart';

import '../../../test_utils/recording_exporter.dart';

void main() {
  late RecordingExporter exporter;
  late ExportArticlesUseCase exportUseCase;

  setUp(() {
    exporter = RecordingExporter();
    exportUseCase = ExportArticlesUseCase(exporter);
  });

  List<ArticleEntity> buildArticles() {
    return const [
      ArticleEntity(
        title: 'Article One',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.1234/one',
        publishedYear: 2024,
      ),
      ArticleEntity(
        title: 'Article Two',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.1234/two',
        publishedYear: 2023,
      ),
      ArticleEntity(
        title: 'Article Three',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.1234/three',
        publishedYear: 2022,
      ),
    ];
  }

  test('markAddAndNext stores selection and advances index', () {
    final viewModel = StageReviewViewModel(
      items: buildArticles(),
      exportArticlesUseCase: exportUseCase,
    );

    expect(viewModel.index, 0);
    expect(viewModel.selectedIds, isEmpty);

    viewModel.markAddAndNext();

    expect(viewModel.index, 1);
    expect(viewModel.selectedIds.length, 1);
    expect(viewModel.isSummaryVisible, isFalse);
  });

  test('markRemoveAndNext removes selection and advances', () {
    final articles = buildArticles();
    final viewModel = StageReviewViewModel(
      items: articles,
      exportArticlesUseCase: exportUseCase,
    );

    viewModel.markAddAndNext(); // select first
    expect(viewModel.selectedIds.length, 1);

    viewModel.markRemoveAndNext(); // remove second

    expect(viewModel.index, 2);
    expect(viewModel.selectedIds.length, 1);
    expect(
      viewModel.selectedIds.contains('10.1234/two'),
      isFalse,
      reason: 'Second article should not remain selected after remove.',
    );
  });

  test('back returns to previous article preserving decisions', () {
    final viewModel = StageReviewViewModel(
      items: buildArticles(),
      exportArticlesUseCase: exportUseCase,
    );

    viewModel.markAddAndNext(); // index 1
    viewModel.markAddAndNext(); // index 2

    expect(viewModel.index, 2);
    expect(viewModel.selectedIds.length, 2);

    viewModel.back();

    expect(viewModel.index, 1);
    expect(
      viewModel.selectedIds.length,
      2,
      reason: 'Selections should persist when navigating back.',
    );
  });

  test('end-of-list triggers summary visibility', () {
    final viewModel = StageReviewViewModel(
      items: buildArticles(),
      exportArticlesUseCase: exportUseCase,
    );

    viewModel.markAddAndNext();
    viewModel.markAddAndNext();
    viewModel.markAddAndNext();

    expect(viewModel.isSummaryVisible, isTrue);
    expect(viewModel.index, 2);
  });

  test('selectedArticles deduplicates by doi before export', () async {
    final articles = [
      const ArticleEntity(
        title: 'First',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.1234/shared',
      ),
      const ArticleEntity(
        title: 'Second',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.1234/shared',
      ),
    ];

    final viewModel = StageReviewViewModel(
      items: articles,
      exportArticlesUseCase: exportUseCase,
    );

    viewModel.markAddAndNext();
    viewModel.markAddAndNext();

    expect(viewModel.isSummaryVisible, isTrue);

    final exportResult = await viewModel.exportSelected();

    expect(exportResult.isSuccess, isTrue);
    expect(exporter.lastExport, isNotNull);
    expect(
      exporter.lastExport!.length,
      1,
      reason: 'Articles with same DOI should be deduplicated.',
    );
    expect(exporter.lastExport!.first.title, 'First');
  });

  test('snapshot captures index selections and summary flag', () {
    final articles = buildArticles();
    final viewModel = StageReviewViewModel(
      items: articles,
      exportArticlesUseCase: exportUseCase,
    );

    viewModel.markAddAndNext();
    viewModel.markAddAndNext();
    viewModel.markAddAndNext();

    final snapshot = viewModel.snapshot();

    expect(snapshot.index, 2);
    expect(snapshot.showSummary, isTrue);
    expect(snapshot.selectedIds.length, 3);
  });
}
