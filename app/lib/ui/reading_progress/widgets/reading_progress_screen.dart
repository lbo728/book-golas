import 'package:flutter/material.dart';

import 'package:book_golas/domain/models/book.dart';
import 'package:book_golas/ui/book_detail/book_detail_screen.dart';

class ReadingProgressScreen extends StatelessWidget {
  final Book book;
  final void Function(VoidCallback updatePage, VoidCallback addMemorable)?
      onCallbacksReady;

  const ReadingProgressScreen({
    super.key,
    required this.book,
    this.onCallbacksReady,
  });

  @override
  Widget build(BuildContext context) {
    return BookDetailScreen(
      key: ValueKey(book.id),
      book: book,
      isEmbedded: true,
      onCallbacksReady: onCallbacksReady,
    );
  }
}
