import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:book_golas/domain/models/note_structure_models.dart';
import 'package:book_golas/data/services/note_structure_service.dart';
import 'package:book_golas/ui/book_detail/view_model/note_structure_view_model.dart';

class MockNoteStructureService extends Mock implements NoteStructureService {}

void main() {
  group('NoteStructureViewModel', () {
    late MockNoteStructureService mockService;
    late NoteStructureViewModel viewModel;

    setUp(() {
      mockService = MockNoteStructureService();
      viewModel = NoteStructureViewModel(service: mockService);
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(viewModel.isLoading, false);
        expect(viewModel.structure, null);
        expect(viewModel.errorMessage, null);
      });
    });

    group('loadStructure', () {
      test('should set isLoading to true before loading', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.getStructure('book-123'))
            .thenAnswer((_) async => testStructure);

        final loadingStates = <bool>[];
        viewModel.addListener(() {
          loadingStates.add(viewModel.isLoading);
        });

        await viewModel.loadStructure('book-123');

        expect(loadingStates.contains(true), true);
      });

      test('should set isLoading to false after loading', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.getStructure('book-123'))
            .thenAnswer((_) async => testStructure);

        await viewModel.loadStructure('book-123');

        expect(viewModel.isLoading, false);
      });

      test('should load existing structure from service', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.getStructure('book-123'))
            .thenAnswer((_) async => testStructure);

        await viewModel.loadStructure('book-123');

        expect(viewModel.structure, testStructure);
        expect(viewModel.errorMessage, null);
        verify(() => mockService.getStructure('book-123')).called(1);
      });

      test('should generate new structure if none exists', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.getStructure('book-123'))
            .thenAnswer((_) async => null);
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => testStructure);

        await viewModel.loadStructure('book-123');

        expect(viewModel.structure, testStructure);
        expect(viewModel.errorMessage, null);
        verify(() => mockService.getStructure('book-123')).called(1);
        verify(() => mockService.structureNotes('book-123')).called(1);
      });

      test(
          'should set error message when both getStructure and structureNotes fail',
          () async {
        when(() => mockService.getStructure('book-123'))
            .thenAnswer((_) async => null);
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => null);

        await viewModel.loadStructure('book-123');

        expect(viewModel.structure, null);
        expect(viewModel.errorMessage, '노트 구조화에 실패했습니다');
        expect(viewModel.isLoading, false);
      });

      test('should clear error message on successful load', () async {
        // First, set an error state
        when(() => mockService.getStructure('book-123'))
            .thenAnswer((_) async => null);
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => null);
        await viewModel.loadStructure('book-123');
        expect(viewModel.errorMessage, '노트 구조화에 실패했습니다');

        // Then load successfully
        final testStructure = _createTestStructure();
        when(() => mockService.getStructure('book-456'))
            .thenAnswer((_) async => testStructure);
        await viewModel.loadStructure('book-456');

        expect(viewModel.errorMessage, null);
        expect(viewModel.structure, testStructure);
      });

      test('should call notifyListeners on state change', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.getStructure('book-123'))
            .thenAnswer((_) async => testStructure);

        var notifyCount = 0;
        viewModel.addListener(() {
          notifyCount++;
        });

        await viewModel.loadStructure('book-123');

        // Should be called at least twice: once when setting isLoading=true, once when done
        expect(notifyCount >= 2, true);
      });
    });

    group('regenerateStructure', () {
      test('should set isLoading to true before regenerating', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => testStructure);

        final loadingStates = <bool>[];
        viewModel.addListener(() {
          loadingStates.add(viewModel.isLoading);
        });

        await viewModel.regenerateStructure('book-123');

        expect(loadingStates.contains(true), true);
      });

      test('should set isLoading to false after regenerating', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => testStructure);

        await viewModel.regenerateStructure('book-123');

        expect(viewModel.isLoading, false);
      });

      test('should regenerate structure via service', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => testStructure);

        await viewModel.regenerateStructure('book-123');

        expect(viewModel.structure, testStructure);
        expect(viewModel.errorMessage, null);
        verify(() => mockService.structureNotes('book-123')).called(1);
      });

      test('should set error message when regeneration fails', () async {
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => null);

        await viewModel.regenerateStructure('book-123');

        expect(viewModel.structure, null);
        expect(viewModel.errorMessage, '노트 구조화에 실패했습니다');
        expect(viewModel.isLoading, false);
      });

      test('should clear error message on successful regeneration', () async {
        // First, set an error state
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => null);
        await viewModel.regenerateStructure('book-123');
        expect(viewModel.errorMessage, '노트 구조화에 실패했습니다');

        // Then regenerate successfully
        final testStructure = _createTestStructure();
        when(() => mockService.structureNotes('book-456'))
            .thenAnswer((_) async => testStructure);
        await viewModel.regenerateStructure('book-456');

        expect(viewModel.errorMessage, null);
        expect(viewModel.structure, testStructure);
      });

      test('should call notifyListeners on state change', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => testStructure);

        var notifyCount = 0;
        viewModel.addListener(() {
          notifyCount++;
        });

        await viewModel.regenerateStructure('book-123');

        // Should be called at least twice: once when setting isLoading=true, once when done
        expect(notifyCount >= 2, true);
      });

      test('should not call getStructure during regeneration', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.structureNotes('book-123'))
            .thenAnswer((_) async => testStructure);

        await viewModel.regenerateStructure('book-123');

        verifyNever(() => mockService.getStructure(any()));
      });
    });

    group('State Management', () {
      test('should maintain state across multiple operations', () async {
        final testStructure1 = _createTestStructure();
        final testStructure2 = _createTestStructure();

        when(() => mockService.getStructure('book-123'))
            .thenAnswer((_) async => testStructure1);
        when(() => mockService.structureNotes('book-456'))
            .thenAnswer((_) async => testStructure2);

        await viewModel.loadStructure('book-123');
        expect(viewModel.structure, testStructure1);

        await viewModel.regenerateStructure('book-456');
        expect(viewModel.structure, testStructure2);
      });

      test('should handle rapid successive calls', () async {
        final testStructure = _createTestStructure();
        when(() => mockService.getStructure(any()))
            .thenAnswer((_) async => testStructure);

        await Future.wait([
          viewModel.loadStructure('book-1'),
          viewModel.loadStructure('book-2'),
          viewModel.loadStructure('book-3'),
        ]);

        expect(viewModel.isLoading, false);
        expect(viewModel.structure, testStructure);
      });
    });
  });
}

NoteStructure _createTestStructure() {
  return NoteStructure(
    bookId: 'book-123',
    generatedAt: DateTime.now(),
    clusters: [
      Cluster(
        id: 'cluster-1',
        name: 'Test Cluster',
        summary: 'Test summary',
        nodes: [
          Node(
            id: 'node-1',
            type: 'note',
            content: 'Test content',
          ),
        ],
      ),
    ],
    connections: [
      Connection(
        fromNodeId: 'node-1',
        toNodeId: 'node-2',
        reason: 'Test connection',
      ),
    ],
  );
}
