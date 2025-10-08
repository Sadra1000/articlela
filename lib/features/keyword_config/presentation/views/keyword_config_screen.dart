import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../app/navigation/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/keyword_group_entity.dart';
import '../../domain/entities/search_filter_entity.dart';
import '../viewmodels/keyword_config_viewmodel.dart';

class KeywordConfigScreen extends StatelessWidget {
  const KeywordConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<KeywordConfigViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.keywordConfigTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    l10n.keywordConfigSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  child: Lottie.asset('assets/lottie/keyword.json'),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        _GroupList(viewModel: viewModel),
        SizedBox(height: 24.h),
        _FiltersSection(viewModel: viewModel),
        SizedBox(height: 32.h),
        Align(
          alignment: Alignment.centerRight,
          child: CustomButton(
            label: l10n.keywordConfigNext,
            onPressed: () => _handleNext(context, viewModel),
          ),
        ),
      ],
    );
  }

  Future<void> _handleNext(BuildContext context, KeywordConfigViewModel viewModel) async {
    final l10n = context.l10n;
    final validation = viewModel.validate();
    if (validation == 'no_groups') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.keywordConfigErrorNoGroups)),
      );
      return;
    }
    if (validation == 'empty_keywords') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.keywordConfigErrorEmpty)),
      );
      return;
    }
    if (validation == 'no_sources') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.keywordConfigErrorNoSources)),
      );
      return;
    }

    await viewModel.persist();

    final filter = viewModel.buildFilter();
    if (context.mounted) {
      Navigator.of(context).pushNamed(AppRouter.results, arguments: filter);
    }
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({required this.viewModel});

  final KeywordConfigViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = viewModel.groups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.keywordConfigTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            TextButton.icon(
              onPressed: viewModel.addGroup,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                l10n.keywordConfigAddGroup,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ...groups.asMap().entries.map(
          (entry) => _GroupCard(
            index: entry.key,
            group: entry.value,
            viewModel: viewModel,
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.index,
    required this.group,
    required this.viewModel,
  });

  final int index;
  final KeywordGroupEntity group;
  final KeywordConfigViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: group.name,
                  decoration: InputDecoration(
                    labelText: l10n.keywordConfigGroupName(index + 1),
                  ),
                  onChanged: (value) => viewModel.renameGroup(group.id, value),
                ),
              ),
              IconButton(
                onPressed: () => viewModel.removeGroup(group.id),
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Column(
            children: [
              for (int i = 0; i < group.keywords.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: TextFormField(
                    initialValue: group.keywords[i],
                    decoration: InputDecoration(
                      labelText: '${l10n.keywordConfigKeywordHint} ${i + 1}',
                    ),
                    onChanged: (value) => viewModel.updateKeyword(group.id, i, value),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => viewModel.addKeyword(group.id),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                l10n.keywordConfigAddKeyword,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({required this.viewModel});

  final KeywordConfigViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final docTypes = KeywordConfigViewModel.availableDocTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.keywordConfigYearRange,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        SizedBox(height: 12.h),
        _YearRangeSlider(viewModel: viewModel),
        SizedBox(height: 24.h),
        Text(
          l10n.keywordConfigSources,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: DataSource.values.map((source) {
            final enabled = source != DataSource.scopus || viewModel.scopusAvailable;
            final chip = FilterChip(
              label: Text(_sourceLabel(l10n, source)),
              selected: viewModel.selectedSources.contains(source),
              onSelected: enabled ? (_) => viewModel.toggleSource(source) : null,
            );
            if (enabled) return chip;
            return Tooltip(
              message: l10n.keywordConfigScopusDisabledHint,
              child: chip,
            );
          }).toList(),
        ),
        SizedBox(height: 24.h),
        Text(
          l10n.keywordConfigDocTypes,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [
            for (final docType in docTypes)
              FilterChip(
                label: Text(_docTypeLabel(l10n, docType)),
                selected: viewModel.selectedDocTypes.contains(docType),
                onSelected: (_) => viewModel.toggleDocumentType(docType),
              ),
          ],
        ),
      ],
    );
  }

  String _docTypeLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case 'journal_article':
        return l10n.docTypeJournalArticle;
      case 'review':
        return l10n.docTypeReview;
      case 'book':
        return l10n.docTypeBook;
      case 'conference':
        return l10n.docTypeConference;
      case 'report':
        return l10n.docTypeReport;
      case 'thesis':
        return l10n.docTypeThesis;
      default:
        return l10n.docTypeOther;
    }
  }

  String _sourceLabel(AppLocalizations l10n, DataSource source) {
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

class _YearRangeSlider extends StatefulWidget {
  const _YearRangeSlider({required this.viewModel});

  final KeywordConfigViewModel viewModel;

  @override
  State<_YearRangeSlider> createState() => _YearRangeSliderState();
}

class _YearRangeSliderState extends State<_YearRangeSlider> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(
      widget.viewModel.fromYear.toDouble(),
      widget.viewModel.toYear.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant _YearRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _values = RangeValues(
      widget.viewModel.fromYear.toDouble(),
      widget.viewModel.toYear.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minYear = 1990.0;
    final maxYear = AppConstants.currentYear.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RangeSlider(
          values: _values,
          min: minYear,
          max: maxYear,
          divisions: (maxYear - minYear).toInt(),
          onChanged: (values) {
            setState(() => _values = values);
            widget.viewModel.setYearRange(values.start.round(), values.end.round());
          },
        ),
        Text(
          '${_values.start.round()} - ${_values.end.round()}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}


