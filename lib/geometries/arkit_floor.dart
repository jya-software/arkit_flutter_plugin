import 'package:arkit_plugin/geometries/arkit_geometry.dart';
import 'package:arkit_plugin/geometries/arkit_material.dart';

/// Represents a rectangle with controllable width and height. The plane has one visible side.
class ARKitFloor extends ARKitGeometry {
  ARKitFloor({
    List<ARKitMaterial> materials,
  }) : super(
          materials: materials,
        );
  @override
  Map<String, dynamic> toMap() => <String, dynamic>{}..addAll(super.toMap());
}
