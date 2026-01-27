class Node {
  final String id;
  final String type;
  final String content;
  final int? pageNumber;
  final String? sourceId;

  Node({
    required this.id,
    required this.type,
    required this.content,
    this.pageNumber,
    this.sourceId,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      id: json['id'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      pageNumber: json['pageNumber'] as int?,
      sourceId: json['sourceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'pageNumber': pageNumber,
      'sourceId': sourceId,
    };
  }

  Node copyWith({
    String? id,
    String? type,
    String? content,
    int? pageNumber,
    String? sourceId,
  }) {
    return Node(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      sourceId: sourceId ?? this.sourceId,
    );
  }
}

class Connection {
  final String fromNodeId;
  final String toNodeId;
  final String reason;

  Connection({
    required this.fromNodeId,
    required this.toNodeId,
    required this.reason,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      fromNodeId: json['fromNodeId'] as String,
      toNodeId: json['toNodeId'] as String,
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromNodeId': fromNodeId,
      'toNodeId': toNodeId,
      'reason': reason,
    };
  }

  Connection copyWith({
    String? fromNodeId,
    String? toNodeId,
    String? reason,
  }) {
    return Connection(
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      reason: reason ?? this.reason,
    );
  }
}

class Cluster {
  final String id;
  final String name;
  final String summary;
  final List<Node> nodes;

  Cluster({
    required this.id,
    required this.name,
    required this.summary,
    required this.nodes,
  });

  factory Cluster.fromJson(Map<String, dynamic> json) {
    return Cluster(
      id: json['id'] as String,
      name: json['name'] as String,
      summary: json['summary'] as String,
      nodes: (json['nodes'] as List)
          .map((n) => Node.fromJson(n as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'summary': summary,
      'nodes': nodes.map((n) => n.toJson()).toList(),
    };
  }

  Cluster copyWith({
    String? id,
    String? name,
    String? summary,
    List<Node>? nodes,
  }) {
    return Cluster(
      id: id ?? this.id,
      name: name ?? this.name,
      summary: summary ?? this.summary,
      nodes: nodes ?? this.nodes,
    );
  }
}

class NoteStructure {
  final String bookId;
  final DateTime generatedAt;
  final List<Cluster> clusters;
  final List<Connection> connections;

  NoteStructure({
    required this.bookId,
    required this.generatedAt,
    required this.clusters,
    required this.connections,
  });

  factory NoteStructure.fromJson(Map<String, dynamic> json) {
    return NoteStructure(
      bookId: json['bookId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      clusters: (json['clusters'] as List)
          .map((c) => Cluster.fromJson(c as Map<String, dynamic>))
          .toList(),
      connections: (json['connections'] as List)
          .map((c) => Connection.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'generatedAt': generatedAt.toIso8601String(),
      'clusters': clusters.map((c) => c.toJson()).toList(),
      'connections': connections.map((c) => c.toJson()).toList(),
    };
  }

  NoteStructure copyWith({
    String? bookId,
    DateTime? generatedAt,
    List<Cluster>? clusters,
    List<Connection>? connections,
  }) {
    return NoteStructure(
      bookId: bookId ?? this.bookId,
      generatedAt: generatedAt ?? this.generatedAt,
      clusters: clusters ?? this.clusters,
      connections: connections ?? this.connections,
    );
  }
}
