import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _focusNode = FocusNode();
  bool _isDragHovering = false;

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
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: DropTarget(
        onDragEntered: (_) => _setDragging(true),
        onDragUpdated: (_) => _setDragging(true),
        onDragExited: (_) => _setDragging(false),
        onDragDone: _handleDrop,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),

                  _Header(onPickPdf: _pickPdf),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: Consumer<PdfReaderViewModel>(
                      builder: (context, viewModel, _) {
                        if (!viewModel.hasDocument) {
                          return Center(
                            child: _EmptyState(
                              title: l10n.pdfReaderEmptyTitle,
                              description: l10n.pdfReaderEmptyDescription,
                              dropHint: l10n.pdfReaderDropHint,
                              isHovering: _isDragHovering,
                            ),
                          );
                        }
                        return _buildViewer(context, viewModel);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildViewer(BuildContext context, PdfReaderViewModel viewModel) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        theme.colorScheme.surface.withValues(alpha: 0.95),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: gradient),
            child: Material(
              color: Colors.white,
              child: Listener(
                onPointerDown: (_) => _focusNode.requestFocus(),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onSecondaryTapUp: (details) =>
                      _showContextMenu(context, details),
                  child: Stack(
                    children: [
                      SfPdfViewer.file(
                        viewModel.document!,
                        controller: _pdfController,
                        enableTextSelection: true,
                        canShowTextSelectionMenu: false,
                        onTextSelectionChanged: (details) {
                          viewModel.updateSelection(details.selectedText);
                          if ((details.selectedText ?? '').isNotEmpty) {
                            _focusNode.requestFocus();
                          }
                        },
                        onHyperlinkClicked: (details) {
                          _openHyperlink(context, details.uri);
                        },
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _isDragHovering ? 1 : 0,
                        child: _DropOverlay(message: l10n.pdfReaderDropHint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _setDragging(bool value) {
    if (_isDragHovering == value) {
      return;
    }
    setState(() {
      _isDragHovering = value;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final keysPressed = HardwareKeyboard.instance.logicalKeysPressed;
    final hasModifier =
        keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
        keysPressed.contains(LogicalKeyboardKey.controlRight) ||
        keysPressed.contains(LogicalKeyboardKey.metaLeft) ||
        keysPressed.contains(LogicalKeyboardKey.metaRight);
    if (event.logicalKey == LogicalKeyboardKey.keyT && hasModifier) {
      unawaited(_translateSelection());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    _setDragging(false);
    if (!mounted || details.files.isEmpty) {
      return;
    }

    String? filePath;
    for (final file in details.files) {
      final path = file.path;
      if (path.toLowerCase().endsWith('.pdf')) {
        filePath = path;
        break;
      }
    }

    if (filePath == null) {
      _showSnack(context.l10n.pdfReaderFileOpenError);
      return;
    }

    final viewModel = context.read<PdfReaderViewModel>();
    final opened = await viewModel.openDocument(filePath);
    if (!mounted) {
      return;
    }

    if (!opened) {
      _showSnack(context.l10n.pdfReaderFileOpenError);
      return;
    }

    _focusNode.requestFocus();
  }

  Future<void> _showContextMenu(
    BuildContext context,
    TapUpDetails details,
  ) async {
    final viewModel = context.read<PdfReaderViewModel>();
    if (!viewModel.hasSelection) {
      return;
    }
    _focusNode.requestFocus();
    final l10n = context.l10n;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final tapPosition = details.globalPosition;
    final menuPosition = overlay != null
        ? RelativeRect.fromRect(
            Rect.fromPoints(
              overlay.globalToLocal(tapPosition),
              overlay.globalToLocal(tapPosition),
            ),
            Offset.zero & overlay.size,
          )
        : RelativeRect.fromLTRB(
            tapPosition.dx,
            tapPosition.dy,
            tapPosition.dx,
            tapPosition.dy,
          );
    final selected = await showMenu<String>(
      context: context,
      position: menuPosition,
      items: [
        PopupMenuItem(
          value: 'translate',
          child: Text(l10n.pdfReaderContextTranslate),
        ),
        PopupMenuItem(
          value: 'copy',
          child: Text(MaterialLocalizations.of(context).copyButtonLabel),
        ),
        PopupMenuItem(
          value: 'clear',
          child: Text(l10n.pdfReaderCloseTranslation),
        ),
      ],
    );

    switch (selected) {
      case 'translate':
        await _translateSelection();
        break;
      case 'copy':
        final text = viewModel.selectedText;
        if (text != null && text.isNotEmpty) {
          Clipboard.setData(ClipboardData(text: text));
        }
        break;
      case 'clear':
        _pdfController.clearSelection();
        viewModel.clearSelection();
        break;
      default:
        break;
    }
  }

  Future<void> _translateSelection() async {
    final viewModel = context.read<PdfReaderViewModel>();
    final l10n = context.l10n;
    if (!viewModel.hasSelection) {
      _showSnack(l10n.pdfReaderTranslationPrompt);
      return;
    }
    if (viewModel.isTranslating) {
      return;
    }

    try {
      final translation = await viewModel.translateSelection();
      if (!mounted) {
        return;
      }
      if (translation.isEmpty) {
        _showSnack(l10n.pdfReaderTranslationError);
        return;
      }
      final original = viewModel.selectedText ?? '';
      _focusNode.requestFocus();
      unawaited(
        _showTranslationSheet(translation: translation, original: original),
      );
    } on StateError {
      if (!mounted) {
        return;
      }
      _showSnack(l10n.pdfReaderTranslationPrompt);
    } on UnsupportedError {
      if (!mounted) {
        return;
      }
      _showSnack(l10n.pdfReaderTranslationError);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack(l10n.pdfReaderTranslationError);
    }
  }

  Future<void> _showTranslationSheet({
    required String translation,
    required String original,
  }) async {
    if (!mounted) {
      return;
    }
    final l10n = context.l10n;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: l10n.pdfReaderTranslationTitle,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _TranslationTopSheet(
          translation: translation,
          original: original,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.12),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickPdf() async {
    final viewModel = context.read<PdfReaderViewModel>();
    final l10n = context.l10n;
    final result = await viewModel.pickDocument();
    if (!mounted) {
      return;
    }
    if (result == false) {
      _showSnack(l10n.pdfReaderFileOpenError);
      return;
    }
    if (result == true) {
      _focusNode.requestFocus();
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
    final theme = Theme.of(context);
    final fileName = viewModel.fileName;

    return Padding(
      padding:  EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          
          CustomButton(
            label: viewModel.hasDocument
                ? l10n.pdfReaderPickAnother
                : l10n.pdfReaderSelectFile,
            onPressed: viewModel.isPickingFile ? null : onPickPdf,
            icon: const Icon(Icons.picture_as_pdf),
          ),
          SizedBox(width: 16.w),
          if (fileName != null)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Container(
                  key: ValueKey(fileName),
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 18.w,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          l10n.pdfReaderSelectedFile(fileName),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TranslationTopSheet extends StatelessWidget {
  const _TranslationTopSheet({
    required this.translation,
    required this.original,
  });

  final String translation;
  final String original;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.7;
    final copyLabel = MaterialLocalizations.of(context).copyButtonLabel;
    final closeLabel = MaterialLocalizations.of(context).closeButtonLabel;
    final isDark = theme.brightness == Brightness.dark;

    final originalBackground = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: isDark ? 0.45 : 0.75);
    final translationBackground = theme.colorScheme.primaryContainer.withValues(
      alpha: isDark ? 0.85 : 0.95,
    );
    final translationTextColor = theme.colorScheme.onPrimaryContainer;
    final borderColor = theme.dividerColor.withValues(alpha: 0.28);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 24.h, left: 24.w, right: 24.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520.w, maxHeight: maxHeight),
            child: Material(
              color: theme.colorScheme.surface,
              elevation: 18,
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(28.r),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 20.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.translate,
                            size: 24.w,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              l10n.pdfReaderTranslationTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: closeLabel,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      if (original.isNotEmpty) ...[
                        SizedBox(height: 18.h),
                        Text(
                          l10n.pdfReaderTranslationWord,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _TranslationTextBlock(
                          text: original,
                          background: originalBackground,
                          borderColor: borderColor,
                          textStyle: theme.textTheme.bodyMedium,
                        ),
                      ],
                      SizedBox(height: 20.h),
                      Text(
                        l10n.pdfReaderTranslationTitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      _TranslationTextBlock(
                        text: translation,
                        background: translationBackground,
                        borderColor: theme.colorScheme.primary.withValues(
                          alpha: 0.35,
                        ),
                        textStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: translationTextColor,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: translation),
                              );
                              final messenger = ScaffoldMessenger.of(context);
                              messenger.hideCurrentSnackBar();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(copyLabel),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: Text(copyLabel),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l10n.pdfReaderCloseTranslation),
                          ),
                        ],
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
  }
}

class _TranslationTextBlock extends StatelessWidget {
  const _TranslationTextBlock({
    required this.text,
    required this.background,
    required this.borderColor,
    required this.textStyle,
  });

  final String text;
  final Color background;
  final Color borderColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: SelectableText(text, style: textStyle),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.description,
    required this.dropHint,
    required this.isHovering,
  });

  final String title;
  final String description;
  final String dropHint;
  final bool isHovering;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isHovering
        ? theme.colorScheme.primary.withValues(alpha: 0.6)
        : theme.colorScheme.primary.withValues(alpha: 0.2);
    final background = isHovering
        ? theme.colorScheme.primary.withValues(alpha: 0.08)
        : theme.colorScheme.onInverseSurface;

    return AnimatedContainer(
      height: 700.h,
      width: 700.w,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHovering ? Icons.cloud_upload : Icons.picture_as_pdf,
                size: 72.w,
                color: borderColor,
              ),
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

class _DropOverlay extends StatelessWidget {
  const _DropOverlay({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: Container(
        color: theme.colorScheme.primary.withValues(alpha: 0.12),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(color: theme.colorScheme.primary, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48.w,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: 12.h),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
