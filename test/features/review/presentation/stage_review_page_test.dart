import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:articlela/app/l10n/app_localizations.dart';
import 'package:articlela/core/domain/entities/article_entity.dart';
import 'package:articlela/features/review/presentation/stage_review_page.dart';
import 'package:articlela/features/review/presentation/viewmodel/stage_review_viewmodel.dart';
import 'package:articlela/features/search_results/domain/usecases/export_articles_usecase.dart';

import '../../../test_utils/recording_exporter.dart';

void main() {
  late RecordingExporter exporter;
  late ExportArticlesUseCase exportUseCase;
  late List<ArticleEntity> articles;

  setUp(() {
    exporter = RecordingExporter();
    exportUseCase = ExportArticlesUseCase(exporter);
    articles = const [
      ArticleEntity(
        title: 'Alpha Study',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.0001/alpha',
        publishedYear: 2024,
      ),
      ArticleEntity(
        title: 'Beta Study',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.0001/beta',
        publishedYear: 2023,
      ),
    ];
  });

  Widget buildApp(StageReviewViewModel viewModel) {
    return ScreenUtilInit(
      designSize: const Size(1440, 900),
      minTextAdapt: true,
      builder: (context, _) {
        return MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ChangeNotifierProvider<StageReviewViewModel>.value(
              value: viewModel,
              child: StageReviewPage(
                articleBuilder: (context, article) {
                  return Center(
                    child: Text(
                      article.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  testWidgets('Review flow updates progress and summary information', (
    tester,
  ) async {
    final viewModel = StageReviewViewModel(
      items: articles,
      exportArticlesUseCase: exportUseCase,
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(buildApp(viewModel));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stageReview.addButton')));
    await tester.pumpAndSettle();

    expect(viewModel.index, 1);
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stageReview.backButton')));
    await tester.pumpAndSettle();

    expect(viewModel.index, 0);
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stageReview.addButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stageReview.removeButton')));
    await tester.pumpAndSettle();

    expect(viewModel.isSummaryVisible, isTrue);
    expect(find.text('Review Summary'), findsOneWidget);
    expect(find.text('1 selected for export'), findsOneWidget);
    expect(find.textContaining('Alpha Study'), findsOneWidget);
    expect(find.textContaining('Year'), findsWidgets);
  });
}
