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

  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  int get selectedTabIndex => _selectedTabIndex;
  int? get selectedYear => _selectedYear;
  String? get selectedGenre => _selectedGenre;
  int? get selectedRating => _selectedRating;

  List<Book> get completedBooks => _books
      .where(
        (b) =>
            b.status == BookStatus.completed.value ||
            (b.currentPage >= b.totalPages && b.totalPages > 0),
      )
      .toList();

  List<Book> get filteredBooks {
    var result = completedBooks;
    if (_selectedYear != null) {
      result = result.where((b) => b.startDate.year == _selectedYear).toList();
    }
    if (_selectedGenre != null) {
      result = result.where((b) => b.genre == _selectedGenre).toList();
    }
    if (_selectedRating != null) {
      result = result.where((b) => b.rating == _selectedRating).toList();
    }
    return result;
  }

  List<Book> get booksWithReview => completedBooks
      .where(
        (b) =>
            (b.review != null && b.review!.isNotEmpty) ||
            (b.longReview != null && b.longReview!.isNotEmpty),
      )
      .toList();

  List<int> get availableYears {
    final years = completedBooks.map((b) => b.startDate.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<String> get availableGenres {
    final genres = completedBooks
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
