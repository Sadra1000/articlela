import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../keyword_config/domain/entities/search_filter_entity.dart';
import '../../../review/navigation/review_routes.dart';
import '../../../review/presentation/viewmodel/stage_review_viewmodel.dart';
import '../../../../app/navigation/app_router.dart';
import '../viewmodels/search_results_viewmodel.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, required this.filter});

  final SearchFilterEntity filter;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  bool _emptyToastShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SearchResultsViewModel>().fetchAll(widget.filter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SearchResultsViewModel>();
    final l10n = context.l10n;

    if (!_emptyToastShown &&
        viewModel.ingestionComplete &&
        viewModel.totalResults == 0) {
      _emptyToastShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.searchResultsEmptyAfterFetch)),
        );
      });
    }

    if (viewModel.totalResults > 0 && _emptyToastShown) {
      _emptyToastShown = false;
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(viewModel: viewModel),
          SizedBox(height: 12.h),
          _StageReviewButton(viewModel: viewModel),
          SizedBox(height: 16.h),
          _ProgressPanel(viewModel: viewModel),
          SizedBox(height: 16.h),
          if (viewModel.error != null)
            _ErrorBanner(message: viewModel.error!)
          else if (viewModel.ingestionComplete && viewModel.articles.isEmpty)
            _EmptyPlaceholder(l10n: l10n)
          else
            Expanded(
              child: viewModel.isFetching && viewModel.articles.isEmpty
                  ? const Center(child: LoadingIndicator())
                  : _ResultsList(viewModel: viewModel),
            ),
          SizedBox(height: 16.h),
          if (viewModel.ingestionComplete && viewModel.totalResults > 0)
            _Footer(viewModel: viewModel),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.viewModel});

  final SearchResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    final subtitleStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: Colors.white70);

    final subtitle = viewModel.ingestionComplete
        ? l10n.searchResultsTotal(viewModel.formattedTotalCount())
        : l10n.searchResultsCombinedProgress(
            viewModel.combinedFetched.toString(),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.searchResultsTitle, style: titleStyle),
        SizedBox(height: 8.h),
        Text(subtitle, style: subtitleStyle),
      ],
    );
  }
}

class _StageReviewButton extends StatelessWidget {
  const _StageReviewButton({required this.viewModel});

  final SearchResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: CustomButton(
        label: l10n.stageReviewButton,
        onPressed: viewModel.totalResults == 0
            ? null
            : () async {
                final items = viewModel.allArticles;
                if (items.isEmpty) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.searchResultsEmptyAfterFetch)),
                  );
                  return;
                }
                final result = await Navigator.of(context).pushNamed(
                  AppRouter.stageReview,
                  arguments: StageReviewArguments(
                    items: items,
                    initialState: viewModel.stageReviewState,
                  ),
                );
                if (!context.mounted) return;
                if (result is StageReviewState) {
                  viewModel.updateStageReviewState(result);
                }
              },
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.viewModel});

  final SearchResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (viewModel.progress.isEmpty && !viewModel.isFetching) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (viewModel.isFetching && !viewModel.ingestionComplete)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                l10n.searchResultsFetching,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
          if (viewModel.selectedSourceCount > 0)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                l10n.searchResultsSourceStatus(
                  viewModel.progress.length,
                  viewModel.selectedSourceCount,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white60),
              ),
            ),
          ...viewModel.progress.map(
            (progress) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  _SourceChip(source: progress.source),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      l10n.searchResultsSourceProgress(
                        _sourceLabel(context, progress.source),
                        progress.fetchedItems,
                        progress.fetchedPages,
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ),
                  if (progress.done)
                    Icon(
                      Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 18.w,
                    )
                  else
                    const SizedBox(
                      height: 20,
                      width: 20,
                      child: LoadingIndicator(size: 20),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(BuildContext context, DataSource source) {
    final l10n = context.l10n;
    switch (source) {
      case DataSource.crossref:
        return l10n.searchResultsSourceCrossref;
      case DataSource.scopus:
        return l10n.searchResultsSourceScopus;
      case DataSource.openalex:
        return l10n.keywordConfigSourceOpenAlex;
    }
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.source});

  final DataSource source;

  @override
  Widget build(BuildContext context) {
    final label = _label(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }

  String _label(BuildContext context) {
    final l10n = context.l10n;
    switch (source) {
      case DataSource.crossref:
        return l10n.searchResultsSourceCrossref;
      case DataSource.scopus:
        return l10n.searchResultsSourceScopus;
      case DataSource.openalex:
        return l10n.keywordConfigSourceOpenAlex;
    }
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.viewModel});

  final SearchResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: viewModel.articles.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final article = viewModel.articles[index];
        return _ResultTile(article: article);
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.article});

  final ArticleEntity article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metadataStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.white70);
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRouter.articleDetails, arguments: article),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(article.title, style: titleStyle),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 8.h,
              children: [
                _InfoBadge(
                  label:
                      '${l10n.searchResultsYear}: ${article.publishedYear ?? '-'}',
                ),
                _InfoBadge(
                  label: '${l10n.searchResultsSource}: ${article.source}',
                ),
                _InfoBadge(
                  label:
                      '${l10n.searchResultsDocumentType}: ${_docTypeLabel(l10n, article.documentType)}',
                ),
              ],
            ),
            if (article.doi != null) ...[
              SizedBox(height: 8.h),
              Text('DOI: ${article.doi}', style: metadataStyle),
              TextButton(
                onPressed: () => _openDoi(article.doi!),
                child: Text(l10n.searchResultsOpenDoi),
              ),
            ],
            if (article.link != null) ...[
              SizedBox(height: 4.h),
              TextButton(
                onPressed: () => _launch(article.link!),
                child: Text(l10n.searchResultsOpenLink),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openDoi(String doi) {
    final uri = Uri.parse('https://doi.org/$doi');
    launchUrl(uri);
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _docTypeLabel(AppLocalizations l10n, String value) {
    switch (value.toLowerCase()) {
      case 'preprint':
        return l10n.docTypeJournalPrePrint;
      case 'journal-article':
      case 'ar':
      case 'article':
        return l10n.docTypeJournalArticle;
      case 'review':
      case 're':
        return l10n.docTypeReview;
      case 'book':
      case 'bk':
        return l10n.docTypeBook;
      case 'proceedings-article':
      case 'conference':
      case 'cp':
        return l10n.docTypeConference;
      case 'report':
      case 'rp':
        return l10n.docTypeReport;
      case 'dissertation':
      case 'thesis':
      case 'dp':
        return l10n.docTypeThesis;
      default:
        return l10n.docTypeOther;
    }
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.viewModel});

  final SearchResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.searchResultsShowingLimited(
              viewModel.formattedVisibleCount(),
              viewModel.formattedTotalCount(),
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _SortMenu(viewModel: viewModel),
              SizedBox(width: 16.w),
              CustomButton(
                label: l10n.searchResultsExport,
                onPressed: viewModel.totalResults == 0 || viewModel.isExporting
                    ? null
                    : () async {
                        final result = await viewModel.exportCsv();
                        if (!context.mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        if (result.isSuccess) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.csvExportSuccess)),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.csvExportFailure)),
                          );
                        }
                      },
                icon: viewModel.isExporting
                    ? const LoadingIndicator(size: 20)
                    : null,
              ),
              if (viewModel.canShowMore) ...[
                SizedBox(width: 16.w),
                CustomButton(
                  label: l10n.searchResultsShowMore(
                    AppConstants.defaultVisibleLimit,
                  ),
                  isPrimary: false,
                  onPressed: viewModel.showNextBatch,
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            l10n.searchResultsExportHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.viewModel});

  final SearchResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<SearchSortOption>(
      tooltip: l10n.searchResultsSort,
      initialValue: viewModel.sortOption,
      onSelected: viewModel.sortBy,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SearchSortOption.nameAsc,
          child: Text(l10n.searchResultsSortNameAsc),
        ),
        PopupMenuItem(
          value: SearchSortOption.nameDesc,
          child: Text(l10n.searchResultsSortNameDesc),
        ),
        PopupMenuItem(
          value: SearchSortOption.yearAsc,
          child: Text(l10n.searchResultsSortYearAsc),
        ),
        PopupMenuItem(
          value: SearchSortOption.yearDesc,
          child: Text(l10n.searchResultsSortYearDesc),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sort, color: Colors.white, size: 20.w),
          SizedBox(width: 8.w),
          Text(
            l10n.searchResultsSort,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Center(
        child: Text(
          l10n.searchResultsEmptyAfterFetch,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white70),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}
