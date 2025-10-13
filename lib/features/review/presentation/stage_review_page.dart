import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:articlela/app/di/service_locator.dart';
import 'package:articlela/app/l10n/app_localizations.dart';
import 'package:articlela/core/domain/entities/article_entity.dart';
import 'package:articlela/core/widgets/custom_button.dart';
import 'package:articlela/core/widgets/loading_indicator.dart';
import 'package:articlela/features/article_details/presentation/viewmodels/article_details_viewmodel.dart';
import 'package:articlela/features/article_details/presentation/views/article_details_screen.dart';
import 'package:articlela/features/review/presentation/widgets/review_footer_controls.dart';
import 'package:articlela/features/review/presentation/viewmodel/stage_review_viewmodel.dart';

typedef StageReviewArticleBuilder =
    Widget Function(BuildContext context, ArticleEntity article);

class StageReviewPage extends StatefulWidget {
  const StageReviewPage({super.key, this.articleBuilder});

  final StageReviewArticleBuilder? articleBuilder;

  @override
  State<StageReviewPage> createState() => _StageReviewPageState();
}

class _StageReviewPageState extends State<StageReviewPage> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'stage_review_focus');
  bool _emptyToastShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StageReviewViewModel>();
    final l10n = context.l10n;

    if (viewModel.totalCount == 0 && !_emptyToastShown) {
      _emptyToastShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.searchResultsEmptyAfterFetch)),
        );
      });
    }

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const _BackIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): const _RemoveIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const _AddIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const _AddIntent(),
        LogicalKeySet(LogicalKeyboardKey.numpadEnter): const _AddIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _BackIntent: CallbackAction<_BackIntent>(
            onInvoke: (_) {
              if (!viewModel.isSummaryVisible) {
                viewModel.back();
              }
              return null;
            },
          ),
          _RemoveIntent: CallbackAction<_RemoveIntent>(
            onInvoke: (_) {
              if (!viewModel.isSummaryVisible) {
                viewModel.markRemoveAndNext();
              }
              return null;
            },
          ),
          _AddIntent: CallbackAction<_AddIntent>(
            onInvoke: (_) {
              if (!viewModel.isSummaryVisible) {
                viewModel.markAddAndNext();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          focusNode: _focusNode,
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height:  MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (viewModel.totalCount == 0)
                    Expanded(
                      child: _EmptyState(
                        onClose: () =>
                            Navigator.of(context).pop(viewModel.snapshot()),
                      ),
                    )
                  else if (viewModel.isSummaryVisible)
                    Expanded(
                      child: _SummaryContent(
                        onClose: () =>
                            Navigator.of(context).pop(viewModel.snapshot()),
                      ),
                    )
                  else
                    Expanded(
                      child: _ReviewContent(
                        articleBuilder: widget.articleBuilder,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewContent extends StatelessWidget {
  const _ReviewContent({this.articleBuilder});

  final StageReviewArticleBuilder? articleBuilder;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StageReviewViewModel>();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final article = viewModel.current;

    if (article == null) {
      return Center(
        child: Text(
          l10n.searchResultsEmptyAfterFetch,
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stageReviewProgress(
            viewModel.progressCurrent,
            viewModel.totalCount,
          ),
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        SizedBox(height: 16.h),
        Expanded(
          child: _ArticleDetailsView(
            article: article,
            index: viewModel.index,
            builder: articleBuilder,
          ),
        ),
        SizedBox(height: 24.h),
        ReviewFooterControls(
          onBack: viewModel.back,
          onRemove: viewModel.markRemoveAndNext,
          onAdd: viewModel.markAddAndNext,
          enableBack: viewModel.index > 0,
          enableNext: viewModel.totalCount > 0,
        ),
      ],
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StageReviewViewModel>();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final selections = viewModel.selectedArticles();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stageReviewSummaryTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          l10n.stageReviewSummarySelected(selections.length),
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
        ),
        SizedBox(height: 4.h),
        Text(
          l10n.stageReviewProgress(selections.length, viewModel.totalCount),
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white60),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: selections.isEmpty
              ? Center(
                  child: Text(
                    l10n.stageReviewSummaryNoneSelected,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: selections.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final item = selections[index];
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Wrap(
                            spacing: 12.w,
                            runSpacing: 4.h,
                            children: [
                              Text(
                                '${l10n.searchResultsYear}: ${item.publishedYear ?? '-'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                'DOI: ${item.doi ?? '-'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: l10n.stageReviewSummaryRestart,
                isPrimary: false,
                onPressed: viewModel.isExporting ? null : viewModel.restart,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: CustomButton(
                label: l10n.stageReviewSummaryClose,
                isPrimary: false,
                onPressed: viewModel.isExporting ? null : onClose,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: CustomButton(
                label: l10n.stageReviewSummaryExport,
                onPressed: viewModel.isExporting
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final result = await viewModel.exportSelected();
                        if (!context.mounted) return;
                        if (result.isSuccess) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.csvExportSuccess)),
                          );
                        } else {
                          if (result.message == 'no_selection') {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.stageReviewSummaryNoneSelected,
                                ),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(content: Text(l10n.csvExportFailure)),
                            );
                          }
                        }
                      },
                icon: viewModel.isExporting
                    ? const LoadingIndicator(size: 20)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArticleDetailsView extends StatelessWidget {
  const _ArticleDetailsView({
    required this.article,
    required this.index,
    this.builder,
  });

  final ArticleEntity article;
  final int index;
  final StageReviewArticleBuilder? builder;

  @override
  Widget build(BuildContext context) {
    if (builder != null) {
      return builder!(context, article);
    }

    return ChangeNotifierProvider(
      key: ValueKey<int>(index),
      create: (_) => getIt<ArticleDetailsViewModel>(),
      child: ArticleDetailsScreen(
        key: ValueKey<String>('stage_review_details_$index'),
        article: article,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.searchResultsEmptyAfterFetch,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
        SizedBox(height: 24.h),
        CustomButton(label: l10n.stageReviewSummaryClose, onPressed: onClose),
      ],
    );
  }
}

class _BackIntent extends Intent {
  const _BackIntent();
}

class _RemoveIntent extends Intent {
  const _RemoveIntent();
}

class _AddIntent extends Intent {
  const _AddIntent();
}
