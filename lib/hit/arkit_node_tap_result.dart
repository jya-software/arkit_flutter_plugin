/// The result of users pinch gesture interaction with nodes
class ARKitNodeTapResult {
  ARKitNodeTapResult._(this.nodeName, this.parentName);

  /// The name of the node which users is interacting with.
  final String nodeName;

  final String parentName;

  static ARKitNodeTapResult fromMap(Map<dynamic, dynamic> map) =>
      ARKitNodeTapResult._(
        map['name'],
        map['parentName'],
      );
}
