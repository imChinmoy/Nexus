import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/animated_gradient_bg.dart';
import '../../../../shared/widgets/brl_app_bar.dart';
import '../../../../shared/widgets/brl_button.dart';
import '../../../../shared/widgets/brl_glass_card.dart';
import '../../../../shared/widgets/brl_text_field.dart';

class CreateEventScreen extends ConsumerWidget {
  const CreateEventScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedGradientBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const BrlAppBar(
          title: 'CREATE EVENT',
          accentColor: AppColors.moduleEvents,
          showBack: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BrlGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  BrlTextField(label: 'Event Title'),
                  const SizedBox(height: 12),
                  BrlTextField(label: 'Description'),
                  const SizedBox(height: 12),
                  BrlTextField(label: 'Venue'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            BrlButton(
              label: 'CREATE EVENT',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
