import 'package:arkit_plugin/light/arkit_light_shadow_mode.dart';
import 'package:arkit_plugin/light/arkit_light_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// ARKitLight represents a light that can be attached to a ARKitNode.
class ARKitLight {
  ARKitLight({
    this.type,
    this.color = Colors.white,
    this.temperature,
    double intensity,
    this.spotInnerAngle,
    this.spotOuterAngle,
    this.shadowMode,
    this.castsShadow,
    this.automaticallyAdjustsShadowProjection,
    this.shadowSampleCount,
    this.shadowRadius,
    this.shadowMapWidth,
    this.shadowMapHeight,
    this.shadowColor,
  }) : intensity = ValueNotifier(intensity ?? 1000);

  /// Light type.
  /// Defaults to ARKitLightType.omni.
  final ARKitLightType type;

  /// Specifies the receiver's color.
  /// Defaults to white.
  /// The renderer multiplies the light's color is by the color derived from the light's temperature.
  final Color color;

  /// This specifies the temperature of the light in Kelvin.
  /// The renderer multiplies the light's color by the color derived from the light's temperature.
  /// Defaults to 6500 (pure white).
  final double temperature;

  /// This intensity is used to modulate the light color.
  /// When used with a physically-based material, this corresponds to the luminous flux of the light, expressed in lumens (lm).
  /// Defaults to 1000.
  final ValueNotifier<double> intensity;

  /// The angle in degrees between the spot direction and the lit element below which the lighting is at full strength.
  /// Defaults to 0.
  final double spotInnerAngle;

  /// The angle in degrees between the spot direction and the lit element after which the lighting is at zero strength.
  /// Defaults to 45 degrees.
  final double spotOuterAngle;

  final ARKitLightShadowMode shadowMode;

  final bool castsShadow;

  final bool automaticallyAdjustsShadowProjection;

  final int shadowSampleCount;

  final double shadowRadius;

  final double shadowMapWidth;

  final double shadowMapHeight;

  final Color shadowColor;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type?.index,
        'color': color?.value,
        'temperature': temperature,
        'intensity': intensity?.value,
        'spotInnerAngle': spotInnerAngle,
        'spotOuterAngle': spotOuterAngle,
        'shadowMode': shadowMode?.index,
        'castsShadow': castsShadow,
        'automaticallyAdjustsShadowProjection': automaticallyAdjustsShadowProjection,
        'shadowSampleCount': shadowSampleCount,
        'shadowRadius': shadowRadius,
        'shadowMapWidth':shadowMapWidth,
        'shadowMapHeight':shadowMapHeight,
        'shadowColor': shadowColor?.value,
      }..removeWhere((String k, dynamic v) => v == null);
}
