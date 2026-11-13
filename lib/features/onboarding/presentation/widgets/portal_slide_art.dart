import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/widgets/portal_loader.dart';
import '../../../../core/widgets/shader_cache.dart';
import 'loop_builder.dart';

/// Page 1: a spinning portal and a phone that shakes now and then.
class PortalSlideArt extends StatelessWidget {
  const PortalSlideArt({this.shaders, super.key});

  final ShaderCache? shaders;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      PortalLoader(
        active: true,
        size: AppSizes.onboardingPortal,
        shaders: shaders,
      ),
      Align(
        alignment: Alignment.bottomRight,
        child: LoopBuilder(
          builder: (context, t) {
            // Two quick shakes in the first third of the loop.
            final shake = t < 1 / 3 ? math.sin(t * 3 * math.pi * 4) : 0.0;
            return Transform.rotate(
              angle: AppSizes.onboardingWiggle * shake,
              child: const Icon(
                Icons.vibration,
                size: AppSizes.onboardingTypeDisc,
                color: AppColors.portalHot,
              ),
            );
          },
        ),
      ),
    ],
  );
}
