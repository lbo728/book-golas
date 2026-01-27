import 'package:flutter/material.dart';

import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/data/services/book_service.dart';

class MyLibraryViewModel extends ChangeNotifier {
  final BookService _bookService = BookService();

  List<Book> _books = [];
  bool _isLoading = false;
  int _selectedTabIndex = 0;
  int? _selectedYear;
  String? _selectedGenre;
  int? _selectedRating;
  String _searchQuery = '';

  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  int get selectedTabIndex => _selectedTabIndex;
  int? get selectedYear => _selectedYear;
  String? get selectedGenre => _selectedGenre;
  int? get selectedRating => _selectedRating;
  String get searchQuery => _searchQuery;

  List<Book> get allBooks => _books;

  List<Book> _applySearchFilter(List<Book> books) {
    if (_searchQuery.isEmpty) return books;
    final query = _searchQuery.toLowerCase();
    return books.where((b) {
      final titleMatch = b.title.toLowerCase().contains(query);
      final authorMatch = b.author?.toLowerCase().contains(query) ?? false;
      return titleMatch || authorMatch;
    }).toList();
  }

  List<Book> get filteredBooks {
    var result = allBooks;
    if (_selectedYear != null) {
      result = result.where((b) => b.startDate.year == _selectedYear).toList();
    }
    if (_selectedGenre != null) {
      result = result.where((b) => b.genre == _selectedGenre).toList();
    }
    if (_selectedRating != null) {
      result = result.where((b) => b.rating == _selectedRating).toList();
    }
    return _applySearchFilter(result);
  }

  List<Book> get booksWithReview {
    final reviewBooks = _books
        .where(
          (b) =>
              (b.review != null && b.review!.isNotEmpty) ||
              (b.longReview != null && b.longReview!.isNotEmpty),
        )
        .toList();
    return _applySearchFilter(reviewBooks);
  }

  List<int> get availableYears {
    final years = allBooks.map((b) => b.startDate.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<String> get availableGenres {
    final genres = allBooks
        .where((b) => b.genre != null && b.genre!.isNotEmpty)
        .map((b) => b.genre!)
        .toSet()
        .toList();
    genres.sort();
    return genres;
  }

  void setSelectedTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void setSelectedYear(int? year) {
    _selectedYear = year;
    notifyListeners();
  }

  void setSelectedGenre(String? genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  void setSelectedRating(int? rating) {
    _selectedRating = rating;
    notifyListeners();
  }

  void clearFilters() {
    _selectedYear = null;
    _selectedGenre = null;
    _selectedRating = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _books = await _bookService.fetchBooks();
    } catch (e) {
      debugPrint('Failed to load books: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
