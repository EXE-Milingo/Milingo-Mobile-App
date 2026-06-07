import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milingo/features/premium/widgets/terms_of_service_view.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TermsOfServiceView(
      onBack: () {
        if (Navigator.of(context).canPop()) {
          context.pop();
        }
      },
    );
  }
}
