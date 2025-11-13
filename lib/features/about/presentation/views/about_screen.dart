import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/l10n/app_localizations.dart';
import '../../../../core/widgets/custom_button.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${info.version} (${info.buildNumber})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
       
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Center(
            child: SizedBox(
              height: 220.h,
              child: Lottie.asset('assets/lottie/coding.json'),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            l10n.aboutParagraphOne,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white),
          ),
          SizedBox(height: 12.h),
          Text(
            l10n.aboutParagraphTwo,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          SizedBox(height: 24.h),
          if (_version != null)
            Text(
              l10n.versionLabel(_version!),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70),
            ),
          SizedBox(height: 24.h),
          Wrap(
            spacing: 16.w,
            runSpacing: 12.h,
            children: [
              CustomButton(
                label: l10n.aboutContact,
                onPressed: () => _launchUri(Uri.parse('mailto:team@articlela.app')),
              ),
              CustomButton(
                label: l10n.aboutSupport,
                isPrimary: false,
                onPressed: () => _launchUri(Uri.parse('https://www.buymeacoffee.com/articlela')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchUri(Uri uri) async {
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch link')),
        );
      }
    }
  }
}
