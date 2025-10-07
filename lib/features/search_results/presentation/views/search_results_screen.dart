import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../keyword_config/domain/entities/search_filter_entity.dart';
import '../viewmodels/search_results_viewmodel.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, required this.filter});

  final SearchFilterEntity filter;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SearchResultsViewModel>().fetchInitial(widget.filter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<SearchResultsViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.searchResultsTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    viewModel.isLoading
                        ? l10n.searchResultsLoading
                        : l10n.searchResultsTotal(viewModel.formattedCount()),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 160.h,
              child: Lottie.asset('assets/lottie/results.json'),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        _ActionRow(viewModel: viewModel),
        SizedBox(height: 16.h),
        if (viewModel.isLoading)
          const Center(child: LoadingIndicator())
        else if (viewModel.error != null)
          _ErrorBanner(message: viewModel.error!)
        else if (viewModel.articles.isEmpty)
          _EmptyPlaceholder(l10n: l10n)
        else
          _ResultsList(viewModel: viewModel),
        if (viewModel.hasMore) ...[
          SizedBox(height: 24.h),
          Align(
            alignment: Alignment.center,
            child: CustomButton(
              label: l10n.searchResultsLoadMore,
              onPressed: viewModel.isLoadingMore ? null : viewModel.loadMore,
              icon: viewModel.isLoadingMore ? const LoadingIndicator(size: 20) : null,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.viewModel});

  final SearchResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Text(
            l10n.searchResultsTotal(viewModel.formattedCount()),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const Spacer(),
          _SortMenu(viewModel: viewModel),
          SizedBox(width: 16.w),
          CustomButton(
            label: l10n.searchResultsExport,
            isPrimary: viewModel.articles.isNotEmpty,
            onPressed: viewModel.articles.isEmpty || viewModel.isExporting
                ? null
                : () async {
                    final result = await viewModel.exportCsv();
                    if (!context.mounted) return;
                    if (result.isSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.csvExportSuccess)),
                      );
                    } else {
                      final message = result.message == 'no_data' ? l10n.searchResultsEmpty : l10n.csvExportFailure;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  },
            icon: viewModel.isExporting ? const LoadingIndicator(size: 20) : null,
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
        PopupMenuItem<SearchSortOption>(
          value: SearchSortOption.nameAsc,
          child: Text(l10n.searchResultsSortNameAsc),
        ),
        PopupMenuItem<SearchSortOption>(
          value: SearchSortOption.nameDesc,
          child: Text(l10n.searchResultsSortNameDesc),
        ),
        PopupMenuItem<SearchSortOption>(
          value: SearchSortOption.yearAsc,
          child: Text(l10n.searchResultsSortYearAsc),
        ),
        PopupMenuItem<SearchSortOption>(
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.viewModel});

  final SearchResultsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: viewModel.articles
          .map(
            (article) => Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 8.h,
                    children: [
                      _Badge(label: '${l10n.searchResultsYear}: ${article.publishedYear ?? '-'}'),
                      _Badge(label: '${l10n.searchResultsSource}: ${article.source}'),
                      _Badge(label: '${l10n.searchResultsDocumentType}: ${_resolveDocType(l10n, article.documentType)}'),
                    ],
                  ),
                  if (article.doi != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'DOI: ${article.doi}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  ExpansionTile(
                    title: Text(
                      l10n.searchResultsAbstract,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
                    ),
                    collapsedIconColor: Colors.white,
                    iconColor: Colors.white,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.w),
                        child: Text(
                          article.abstractText ?? l10n.searchResultsNoAbstract,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                      ),
                      if (article.link != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _launch(article.link!),
                            child: Text(l10n.searchResultsOpenLink),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
}

  Future<void> _launch(String link) async {
    final uri = Uri.parse(link);
    if (!await launchUrl(uri)) {
      // ignore failure silently
    }
  }

  String _resolveDocType(AppLocalizations l10n, String value) {
    switch (value.toLowerCase()) {
      case 'journal-article':
      case 'ar':
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180.h,
          child: Lottie.asset('assets/lottie/loading.json'),
        ),
        SizedBox(height: 16.h),
        Text(
          l10n.searchResultsEmpty,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}
