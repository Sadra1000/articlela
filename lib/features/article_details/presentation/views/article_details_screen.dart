import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/domain/entities/article_entity.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../viewmodels/article_details_viewmodel.dart';

class ArticleDetailsScreen extends StatefulWidget {
  const ArticleDetailsScreen({super.key, required this.article});

  final ArticleEntity article;

  @override
  State<ArticleDetailsScreen> createState() => _ArticleDetailsScreenState();
}

class _ArticleDetailsScreenState extends State<ArticleDetailsScreen> {
  @override
  void initState() {
    super.initState();
    final doi = widget.article.doi;
    if (doi != null && doi.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ArticleDetailsViewModel>().load(doi);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final article = widget.article;
    final viewModel = context.watch<ArticleDetailsViewModel>();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 12.w,
              runSpacing: 8.h,
              children: [
                _InfoChip(
                  label: l10n.searchResultsYear,
                  value: article.publishedYear?.toString() ?? '-',
                ),
                _InfoChip(
                  label: l10n.searchResultsDocumentType,
                  value: article.documentType,
                ),
                _InfoChip(
                  label: l10n.searchResultsSource,
                  value: article.source,
                ),
              ],
            ),
            SizedBox(height: 16.h),
            if (article.doi != null) _DoiActions(doi: article.doi!),
            if (article.link != null) ...[
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () => launchUrl(Uri.parse(article.link!), mode: LaunchMode.externalApplication),
                child: Text(l10n.searchResultsOpenLink),
              ),
            ],
            SizedBox(height: 24.h),
            _AbstractSection(viewModel: viewModel, article: article),
          ],
        ),
      ),
    );
  }
}

class _DoiActions extends StatelessWidget {
  const _DoiActions({required this.doi});

  final String doi;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final url = 'https://doi.org/$doi';
    final messenger = ScaffoldMessenger.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            'DOI: $doi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ),
        SizedBox(width: 12.w),
        CustomButton(
          label: l10n.articleDetailsOpenDoi,
          isPrimary: false,
          onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        ),
        SizedBox(width: 12.w),
        CustomButton(
          label: l10n.articleDetailsCopyLink,
          isPrimary: false,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.articleDetailsCopied)),
            );
          },
        ),
      ],
    );
  }
}

class _AbstractSection extends StatelessWidget {
  const _AbstractSection({required this.viewModel, required this.article});

  final ArticleDetailsViewModel viewModel;
  final ArticleEntity article;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final doi = article.doi;
    if (doi == null || doi.isEmpty) {
      return Text(
        l10n.articleDetailsMissingDoi,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
      );
    }

    if (viewModel.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: LoadingIndicator(),
      );
    }

    if (viewModel.error != null) {
      return Text(
        viewModel.error!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
      );
    }

    final result = viewModel.result;
    if (result == null || (result.abstractText == null || result.abstractText!.isEmpty)) {
      return Text(
        l10n.articleDetailsNoAbstract,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.articleDetailsAbstractLabel(_resolveSourceLabel(l10n, result.resolutionSource)),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        SizedBox(height: 12.h),
        Text(
          result.abstractText!,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70, height: 1.4),
        ),
        if (result.authors.isNotEmpty) ...[
          SizedBox(height: 16.h),
          Text(
            l10n.articleDetailsAuthors,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white),
          ),
          SizedBox(height: 6.h),
          Text(
            result.authors.join(', '),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
        if (result.venue != null && result.venue!.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text(
            '${l10n.articleDetailsVenue}: ${result.venue}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ],
    );
  }

  String _resolveSourceLabel(AppLocalizations l10n, String source) {
    switch (source) {
      case 'SEMANTIC_SCHOLAR':
        return l10n.articleDetailsSourceSemanticScholar;
      case 'OPENALEX':
        return l10n.articleDetailsSourceOpenAlex;
      case 'CROSSREF':
        return l10n.articleDetailsSourceCrossref;
      default:
        return l10n.articleDetailsSourceNone;
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}
