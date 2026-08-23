import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:price_catalog_app/core/constants/app_colors.dart';

class LegalInformationScreen extends StatelessWidget {
  final String title;
  final bool showTerms;

  const LegalInformationScreen({
    super.key,
    required this.title,
    this.showTerms = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: showTerms ? _termsContent() : _privacyContent(),
      ),
    );
  }

  Widget _privacyContent() {
    return const _LegalText(
      title: 'Privacy Policy',
      sections: [
        _LegalSection(
          heading: 'Information we collect',
          body:
              'PriceCatalog collects your name, email address, phone number, business details, city, GST details, and account identifier when you register or update your profile. Traders and administrators may also upload product, business, or document images when using relevant features.',
        ),
        _LegalSection(
          heading: 'How we use information',
          body:
              'We use this information to authenticate accounts, manage trader approvals, publish product catalogues, process requirements, send account and workflow notifications, provide support, and keep the service secure.',
        ),
        _LegalSection(
          heading: 'Firebase and service providers',
          body:
              'The app uses Firebase Authentication, Cloud Firestore, Firebase Storage, and Firebase Cloud Messaging to provide sign-in, data storage, file storage, and notifications. These providers process information only to provide their services to us.',
        ),
        _LegalSection(
          heading: 'Permissions',
          body:
              'Camera and photo library access is requested only when an administrator chooses to capture or select product images. Notifications are optional and can be changed in device Settings.',
        ),
        _LegalSection(
          heading: 'Data retention and deletion',
          body:
              'You can permanently delete your account from My Profile > Delete Account. This removes your Firebase Authentication account and profile. Some business records may be retained where necessary for legitimate business, security, legal, or audit purposes. Contact support if you need information about a retained record.',
        ),
        _LegalSection(
          heading: 'Contact',
          body:
              'For privacy questions or data requests, contact the app owner using the support contact published on the App Store product page.',
        ),
      ],
    );
  }

  Widget _termsContent() {
    return const _LegalText(
      title: 'Terms & Conditions',
      sections: [
        _LegalSection(
          heading: 'Use of the app',
          body:
              'You must provide accurate account information and use PriceCatalog only for lawful business activities. Keep your login credentials secure and notify the app owner if you suspect unauthorized access.',
        ),
        _LegalSection(
          heading: 'Account actions',
          body:
              'Administrators manage catalogues and trader approvals. Traders may submit requirements and use approved account features. We may suspend access when an account violates these terms or creates a security risk.',
        ),
        _LegalSection(
          heading: 'Content and uploads',
          body:
              'You are responsible for having the right to upload product images, documents, and other content. Do not upload unlawful, deceptive, or harmful material.',
        ),
        _LegalSection(
          heading: 'Account deletion',
          body:
              'You may delete your account from the in-app Delete Account option. Deletion is permanent and may not remove records that must be retained for legal, security, or business audit purposes.',
        ),
        _LegalSection(
          heading: 'Contact',
          body:
              'Questions about these terms should be sent to the support contact published on the App Store product page.',
        ),
      ],
    );
  }
}

class _LegalText extends StatelessWidget {
  final String title;
  final List<_LegalSection> sections;

  const _LegalText({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Last updated: August 23, 2026',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 24.h),
        ...sections.map(
          (section) => Padding(
            padding: EdgeInsets.only(bottom: 20.h),
            child: section,
          ),
        ),
      ],
    );
  }
}

class _LegalSection extends StatelessWidget {
  final String heading;
  final String body;

  const _LegalSection({required this.heading, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          body,
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
