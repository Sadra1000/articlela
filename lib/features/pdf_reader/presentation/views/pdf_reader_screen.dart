import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/custom_button.dart';
import '../viewmodels/pdf_reader_viewmodel.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final PdfViewerController _pdfController = PdfViewerController();

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onPickPdf: _pickPdf),
              SizedBox(height: 16.h),
              Flexible(
                child: Consumer<PdfReaderViewModel>(
                  builder: (context, viewModel, _) {
                    if (!viewModel.hasDocument) {
                      return _EmptyState(
                        title: l10n.pdfReaderEmptyTitle,
                        description: l10n.pdfReaderEmptyDescription,
                      );
                    }
                    return _buildViewer(
                      context,
                      viewModel,
                      constraints.maxHeight,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewer(
    BuildContext context,
    PdfReaderViewModel viewModel,
    double maxHeight,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface.withValues(alpha: 0.92);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Container(
            color: Colors.white,
            child: SfPdfViewer.file(
              viewModel.document!,
              controller: _pdfController,
              enableTextSelection: true,
              onTextSelectionChanged: (details) {
                final locale = l10n.locale.languageCode;
                final targetLanguage = locale == 'fa' ? 'en' : 'fa';
                viewModel.handleSelection(
                  details.selectedText,
                  targetLanguage: targetLanguage,
                );
              },
              onHyperlinkClicked: (details) {
                _openHyperlink(context, details.uri);
              },
            ),
          ),
        ),
      
       
        _TranslationOverlay(controller: _pdfController, surfaceColor: surface),
      ],
    );
  }

  Future<void> _pickPdf() async {
    final viewModel = context.read<PdfReaderViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final result = await viewModel.pickDocument();
    if (!mounted) {
      return;
    }
    if (result == false) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.pdfReaderFileOpenError)),
      );
    }
  }

  Future<void> _openHyperlink(BuildContext context, String uri) async {
    if (uri.isEmpty) {
      return;
    }
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final errorMessage = l10n.pdfReaderLinkError;
    final parsed = Uri.tryParse(uri);
    if (parsed == null) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }
    final launched = await launchUrl(
      parsed,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) {
      return;
    }
    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onPickPdf});

  final Future<void> Function() onPickPdf;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewModel = context.watch<PdfReaderViewModel>();

    return Row(
      children: [
        CustomButton(
          label: viewModel.hasDocument
              ? l10n.pdfReaderPickAnother
              : l10n.pdfReaderSelectFile,
          onPressed: viewModel.isPickingFile ? null : onPickPdf,
          icon: const Icon(Icons.picture_as_pdf),
        ),
        SizedBox(width: 16.w),
        if (viewModel.fileName != null)
          Flexible(
            child: Text(
              l10n.pdfReaderSelectedFile(viewModel.fileName!),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 48.h),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf, size: 72.w, color: Colors.black54),
              SizedBox(height: 24.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileBadge extends StatelessWidget {
  const _FileBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReferenceHint extends StatelessWidget {
  const _ReferenceHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 18.w, color: theme.colorScheme.primary),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranslationOverlay extends StatelessWidget {
  const _TranslationOverlay({
    required this.controller,
    required this.surfaceColor,
  });

  final PdfViewerController controller;
  final Color surfaceColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Consumer<PdfReaderViewModel>(
      builder: (context, viewModel, _) {
        final isVisible = viewModel.showTranslationSheet;
        return IgnorePointer(
          ignoring: !isVisible,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            offset: isVisible ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: isVisible ? 1 : 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                  child: Material(
                    borderRadius: BorderRadius.circular(28.r),
                    color: surfaceColor,
                    elevation: 12,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.pdfReaderTranslationTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      '${l10n.pdfReaderTranslationWord}: ${viewModel.selectedText ?? ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: l10n.pdfReaderCloseTranslation,
                                onPressed: () {
                                  controller.clearSelection();
                                  viewModel.clearSelection();
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _TranslationContent(
                            isLoading: viewModel.isTranslating,
                            translation: viewModel.translation,
                            error: viewModel.translationError,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TranslationContent extends StatelessWidget {
  const _TranslationContent({
    required this.isLoading,
    this.translation,
    this.error,
  });

  final bool isLoading;
  final String? translation;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isLoading) {
      return Row(
        children: [
          SizedBox(
            width: 24.w,
            height: 24.w,
            child: const CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(width: 12.w),
          Text(
            l10n.pdfReaderTranslationLoading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }

    if (error != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.redAccent, size: 20.w),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              l10n.pdfReaderTranslationError,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.redAccent),
            ),
          ),
        ],
      );
    }

    return Text(
      translation ?? '',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        height: max(1.25, 1.2),
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
