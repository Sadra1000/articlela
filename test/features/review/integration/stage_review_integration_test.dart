import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:articlela/app/l10n/app_localizations.dart';
import 'package:articlela/core/domain/entities/article_entity.dart';
import 'package:articlela/features/review/presentation/stage_review_page.dart';
import 'package:articlela/features/review/presentation/viewmodel/stage_review_viewmodel.dart';
import 'package:articlela/features/search_results/domain/usecases/export_articles_usecase.dart';

import '../../../test_utils/recording_exporter.dart';

void main() {
  testWidgets('Stage review flow exports selected articles', (tester) async {
    final exporter = RecordingExporter();
    final exportUseCase = ExportArticlesUseCase(exporter);
    final articles = const [
      ArticleEntity(
        title: 'First Review',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.111/first',
        publishedYear: 2024,
      ),
      ArticleEntity(
        title: 'Second Review',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.111/second',
        publishedYear: 2023,
      ),
      ArticleEntity(
        title: 'Third Review',
        documentType: 'journal-article',
        source: 'TEST',
        doi: '10.111/third',
        publishedYear: 2022,
      ),
    ];

    final viewModel = StageReviewViewModel(
      items: articles,
      exportArticlesUseCase: exportUseCase,
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
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
                  articleBuilder: (context, article) =>
                      Center(child: Text(article.title)),
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next & Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next & Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next & Add'));
    await tester.pumpAndSettle();

    expect(viewModel.isSummaryVisible, isTrue);

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(exporter.lastExport, isNotNull);
    expect(exporter.lastExport!.length, 2);
    final exportedDois = exporter.lastExport!.map((e) => e.doi).toSet();
    expect(exportedDois.contains('10.111/first'), isTrue);
    expect(exportedDois.contains('10.111/third'), isTrue);
    expect(exportedDois.contains('10.111/second'), isFalse);
  });
}
