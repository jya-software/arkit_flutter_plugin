/// The result of users pinch gesture interaction with nodes
class ARKitNodeRotationResult {
  ARKitNodeRotationResult._(this.nodeName, this.rotation, this.velocity, this.parentName);

  /// The name of the node which users is interacting with.
  final String nodeName;

  final String parentName;

  // The pinch scale value.
  final double rotation;

  final double velocity;

  static ARKitNodeRotationResult fromMap(Map<dynamic, dynamic> map) =>
      ARKitNodeRotationResult._(
        map['name'],
        map['rotation'],
        map['parentName'],
        map['velocity'],
      );
}
