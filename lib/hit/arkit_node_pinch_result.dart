/// The result of users pinch gesture interaction with nodes
class ARKitNodePinchResult {
  ARKitNodePinchResult._(this.nodeName, this.scale, this.parentName);

  /// The name of the node which users is interacting with.
  final String nodeName;

  final String parentName;

  // The pinch scale value.
  final double scale;

  static ARKitNodePinchResult fromMap(Map<dynamic, dynamic> map) =>
      ARKitNodePinchResult._(
        map['name'],
        map['scale'],
        map['parentName'],
      );
}
