import 'package:flutter_test/flutter_test.dart';
import 'package:book_golas/domain/models/note_structure_models.dart';

void main() {
  group('Node', () {
    test('fromJson creates Node with all fields', () {
      final json = {
        'id': 'node-1',
        'type': 'highlight',
        'content': '리더는 비전을 제시해야...',
        'pageNumber': 45,
        'sourceId': 'uuid-123',
      };

      final node = Node.fromJson(json);

      expect(node.id, 'node-1');
      expect(node.type, 'highlight');
      expect(node.content, '리더는 비전을 제시해야...');
      expect(node.pageNumber, 45);
      expect(node.sourceId, 'uuid-123');
    });

    test('fromJson handles nullable pageNumber and sourceId', () {
      final json = {
        'id': 'node-2',
        'type': 'note',
        'content': '메모 내용',
      };

      final node = Node.fromJson(json);

      expect(node.id, 'node-2');
      expect(node.type, 'note');
      expect(node.content, '메모 내용');
      expect(node.pageNumber, isNull);
      expect(node.sourceId, isNull);
    });

    test('toJson serializes Node correctly', () {
      final node = Node(
        id: 'node-1',
        type: 'highlight',
        content: '리더는 비전을 제시해야...',
        pageNumber: 45,
        sourceId: 'uuid-123',
      );

      final json = node.toJson();

      expect(json['id'], 'node-1');
      expect(json['type'], 'highlight');
      expect(json['content'], '리더는 비전을 제시해야...');
      expect(json['pageNumber'], 45);
      expect(json['sourceId'], 'uuid-123');
    });

    test('Node round-trip: fromJson -> toJson -> fromJson', () {
      final originalJson = {
        'id': 'node-1',
        'type': 'photo_ocr',
        'content': '사진 OCR 텍스트',
        'pageNumber': 100,
        'sourceId': 'source-uuid',
      };

      final node1 = Node.fromJson(originalJson);
      final json = node1.toJson();
      final node2 = Node.fromJson(json);

      expect(node2.id, node1.id);
      expect(node2.type, node1.type);
      expect(node2.content, node1.content);
      expect(node2.pageNumber, node1.pageNumber);
      expect(node2.sourceId, node1.sourceId);
    });

    test('copyWith creates new Node with updated fields', () {
      final node = Node(
        id: 'node-1',
        type: 'highlight',
        content: '원본 내용',
        pageNumber: 45,
        sourceId: 'uuid-123',
      );

      final updated = node.copyWith(content: '수정된 내용');

      expect(updated.id, 'node-1');
      expect(updated.type, 'highlight');
      expect(updated.content, '수정된 내용');
      expect(updated.pageNumber, 45);
      expect(updated.sourceId, 'uuid-123');
      expect(identical(node, updated), false);
    });
  });

  group('Connection', () {
    test('fromJson creates Connection with all fields', () {
      final json = {
        'fromNodeId': 'node-1',
        'toNodeId': 'node-3',
        'reason': '동일한 리더십 개념',
      };

      final connection = Connection.fromJson(json);

      expect(connection.fromNodeId, 'node-1');
      expect(connection.toNodeId, 'node-3');
      expect(connection.reason, '동일한 리더십 개념');
    });

    test('toJson serializes Connection correctly', () {
      final connection = Connection(
        fromNodeId: 'node-1',
        toNodeId: 'node-3',
        reason: '동일한 리더십 개념',
      );

      final json = connection.toJson();

      expect(json['fromNodeId'], 'node-1');
      expect(json['toNodeId'], 'node-3');
      expect(json['reason'], '동일한 리더십 개념');
    });

    test('Connection round-trip: fromJson -> toJson -> fromJson', () {
      final originalJson = {
        'fromNodeId': 'node-2',
        'toNodeId': 'node-5',
        'reason': '관련된 개념',
      };

      final conn1 = Connection.fromJson(originalJson);
      final json = conn1.toJson();
      final conn2 = Connection.fromJson(json);

      expect(conn2.fromNodeId, conn1.fromNodeId);
      expect(conn2.toNodeId, conn1.toNodeId);
      expect(conn2.reason, conn1.reason);
    });

    test('copyWith creates new Connection with updated fields', () {
      final connection = Connection(
        fromNodeId: 'node-1',
        toNodeId: 'node-3',
        reason: '원본 이유',
      );

      final updated = connection.copyWith(reason: '수정된 이유');

      expect(updated.fromNodeId, 'node-1');
      expect(updated.toNodeId, 'node-3');
      expect(updated.reason, '수정된 이유');
      expect(identical(connection, updated), false);
    });
  });

  group('Cluster', () {
    test('fromJson creates Cluster with all fields', () {
      final json = {
        'id': 'cluster-1',
        'name': '리더십',
        'summary': '리더십에 관한 핵심 인사이트',
        'nodes': [
          {
            'id': 'node-1',
            'type': 'highlight',
            'content': '리더는 비전을 제시해야...',
            'pageNumber': 45,
            'sourceId': 'uuid-123',
          },
        ],
      };

      final cluster = Cluster.fromJson(json);

      expect(cluster.id, 'cluster-1');
      expect(cluster.name, '리더십');
      expect(cluster.summary, '리더십에 관한 핵심 인사이트');
      expect(cluster.nodes.length, 1);
      expect(cluster.nodes[0].id, 'node-1');
    });

    test('fromJson handles empty nodes list', () {
      final json = {
        'id': 'cluster-2',
        'name': '전략',
        'summary': '전략에 관한 내용',
        'nodes': [],
      };

      final cluster = Cluster.fromJson(json);

      expect(cluster.id, 'cluster-2');
      expect(cluster.nodes.length, 0);
    });

    test('toJson serializes Cluster correctly', () {
      final cluster = Cluster(
        id: 'cluster-1',
        name: '리더십',
        summary: '리더십에 관한 핵심 인사이트',
        nodes: [
          Node(
            id: 'node-1',
            type: 'highlight',
            content: '리더는 비전을 제시해야...',
            pageNumber: 45,
            sourceId: 'uuid-123',
          ),
        ],
      );

      final json = cluster.toJson();

      expect(json['id'], 'cluster-1');
      expect(json['name'], '리더십');
      expect(json['summary'], '리더십에 관한 핵심 인사이트');
      expect(json['nodes'].length, 1);
      expect(json['nodes'][0]['id'], 'node-1');
    });

    test('Cluster round-trip: fromJson -> toJson -> fromJson', () {
      final originalJson = {
        'id': 'cluster-1',
        'name': '리더십',
        'summary': '리더십에 관한 핵심 인사이트',
        'nodes': [
          {
            'id': 'node-1',
            'type': 'highlight',
            'content': '리더는 비전을 제시해야...',
            'pageNumber': 45,
            'sourceId': 'uuid-123',
          },
          {
            'id': 'node-2',
            'type': 'note',
            'content': '메모',
          },
        ],
      };

      final cluster1 = Cluster.fromJson(originalJson);
      final json = cluster1.toJson();
      final cluster2 = Cluster.fromJson(json);

      expect(cluster2.id, cluster1.id);
      expect(cluster2.name, cluster1.name);
      expect(cluster2.summary, cluster1.summary);
      expect(cluster2.nodes.length, cluster1.nodes.length);
      expect(cluster2.nodes[0].id, cluster1.nodes[0].id);
      expect(cluster2.nodes[1].id, cluster1.nodes[1].id);
    });

    test('copyWith creates new Cluster with updated fields', () {
      final cluster = Cluster(
        id: 'cluster-1',
        name: '리더십',
        summary: '원본 요약',
        nodes: [],
      );

      final updated = cluster.copyWith(summary: '수정된 요약');

      expect(updated.id, 'cluster-1');
      expect(updated.name, '리더십');
      expect(updated.summary, '수정된 요약');
      expect(identical(cluster, updated), false);
    });
  });

  group('NoteStructure', () {
    test('fromJson creates NoteStructure with all fields', () {
      final json = {
        'bookId': 'book-uuid',
        'generatedAt': '2026-01-26T10:30:00Z',
        'clusters': [
          {
            'id': 'cluster-1',
            'name': '리더십',
            'summary': '리더십에 관한 핵심 인사이트',
            'nodes': [
              {
                'id': 'node-1',
                'type': 'highlight',
                'content': '리더는 비전을 제시해야...',
                'pageNumber': 45,
                'sourceId': 'uuid-123',
              },
            ],
          },
        ],
        'connections': [
          {
            'fromNodeId': 'node-1',
            'toNodeId': 'node-3',
            'reason': '동일한 리더십 개념',
          },
        ],
      };

      final structure = NoteStructure.fromJson(json);

      expect(structure.bookId, 'book-uuid');
      expect(structure.generatedAt, DateTime.parse('2026-01-26T10:30:00Z'));
      expect(structure.clusters.length, 1);
      expect(structure.clusters[0].id, 'cluster-1');
      expect(structure.connections.length, 1);
      expect(structure.connections[0].fromNodeId, 'node-1');
    });

    test('fromJson handles empty clusters and connections', () {
      final json = {
        'bookId': 'book-uuid',
        'generatedAt': '2026-01-26T10:30:00Z',
        'clusters': [],
        'connections': [],
      };

      final structure = NoteStructure.fromJson(json);

      expect(structure.bookId, 'book-uuid');
      expect(structure.clusters.length, 0);
      expect(structure.connections.length, 0);
    });

    test('toJson serializes NoteStructure correctly', () {
      final structure = NoteStructure(
        bookId: 'book-uuid',
        generatedAt: DateTime.parse('2026-01-26T10:30:00Z'),
        clusters: [
          Cluster(
            id: 'cluster-1',
            name: '리더십',
            summary: '리더십에 관한 핵심 인사이트',
            nodes: [
              Node(
                id: 'node-1',
                type: 'highlight',
                content: '리더는 비전을 제시해야...',
                pageNumber: 45,
                sourceId: 'uuid-123',
              ),
            ],
          ),
        ],
        connections: [
          Connection(
            fromNodeId: 'node-1',
            toNodeId: 'node-3',
            reason: '동일한 리더십 개념',
          ),
        ],
      );

      final json = structure.toJson();

      expect(json['bookId'], 'book-uuid');
      expect(json['generatedAt'], '2026-01-26T10:30:00.000Z');
      expect(json['clusters'].length, 1);
      expect(json['connections'].length, 1);
    });

    test('NoteStructure round-trip: fromJson -> toJson -> fromJson', () {
      final originalJson = {
        'bookId': 'book-uuid',
        'generatedAt': '2026-01-26T10:30:00Z',
        'clusters': [
          {
            'id': 'cluster-1',
            'name': '리더십',
            'summary': '리더십에 관한 핵심 인사이트',
            'nodes': [
              {
                'id': 'node-1',
                'type': 'highlight',
                'content': '리더는 비전을 제시해야...',
                'pageNumber': 45,
                'sourceId': 'uuid-123',
              },
              {
                'id': 'node-2',
                'type': 'note',
                'content': '메모',
              },
            ],
          },
          {
            'id': 'cluster-2',
            'name': '전략',
            'summary': '전략 요약',
            'nodes': [],
          },
        ],
        'connections': [
          {
            'fromNodeId': 'node-1',
            'toNodeId': 'node-2',
            'reason': '관련 개념',
          },
        ],
      };

      final structure1 = NoteStructure.fromJson(originalJson);
      final json = structure1.toJson();
      final structure2 = NoteStructure.fromJson(json);

      expect(structure2.bookId, structure1.bookId);
      expect(structure2.generatedAt, structure1.generatedAt);
      expect(structure2.clusters.length, structure1.clusters.length);
      expect(structure2.clusters[0].id, structure1.clusters[0].id);
      expect(structure2.clusters[0].nodes.length, 2);
      expect(structure2.connections.length, structure1.connections.length);
    });

    test('copyWith creates new NoteStructure with updated fields', () {
      final structure = NoteStructure(
        bookId: 'book-uuid',
        generatedAt: DateTime.parse('2026-01-26T10:30:00Z'),
        clusters: [],
        connections: [],
      );

      final newDateTime = DateTime.parse('2026-01-27T10:30:00Z');
      final updated = structure.copyWith(generatedAt: newDateTime);

      expect(updated.bookId, 'book-uuid');
      expect(updated.generatedAt, newDateTime);
      expect(identical(structure, updated), false);
    });

    test('NoteStructure with complex nested structure', () {
      final json = {
        'bookId': 'book-uuid',
        'generatedAt': '2026-01-26T10:30:00Z',
        'clusters': [
          {
            'id': 'cluster-1',
            'name': '리더십',
            'summary': '리더십에 관한 핵심 인사이트',
            'nodes': [
              {
                'id': 'node-1',
                'type': 'highlight',
                'content': '리더는 비전을 제시해야...',
                'pageNumber': 45,
                'sourceId': 'uuid-123',
              },
              {
                'id': 'node-2',
                'type': 'note',
                'content': '메모',
                'pageNumber': 50,
              },
              {
                'id': 'node-3',
                'type': 'photo_ocr',
                'content': '사진 OCR',
              },
            ],
          },
          {
            'id': 'cluster-2',
            'name': '전략',
            'summary': '전략 요약',
            'nodes': [
              {
                'id': 'node-4',
                'type': 'highlight',
                'content': '전략적 사고',
                'pageNumber': 100,
                'sourceId': 'uuid-456',
              },
            ],
          },
        ],
        'connections': [
          {
            'fromNodeId': 'node-1',
            'toNodeId': 'node-2',
            'reason': '관련 개념',
          },
          {
            'fromNodeId': 'node-2',
            'toNodeId': 'node-4',
            'reason': '다른 관련 개념',
          },
        ],
      };

      final structure = NoteStructure.fromJson(json);

      expect(structure.clusters.length, 2);
      expect(structure.clusters[0].nodes.length, 3);
      expect(structure.clusters[1].nodes.length, 1);
      expect(structure.connections.length, 2);

      // Verify round-trip
      final json2 = structure.toJson();
      final structure2 = NoteStructure.fromJson(json2);

      expect(structure2.clusters.length, 2);
      expect(structure2.clusters[0].nodes.length, 3);
      expect(structure2.clusters[1].nodes.length, 1);
      expect(structure2.connections.length, 2);
    });
  });
}
