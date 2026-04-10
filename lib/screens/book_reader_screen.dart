import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

import '../../services/api_service.dart';

class BookReaderScreen extends StatefulWidget {
  final String url;
  final String title;
  final String ebookId;
  final int initialPage;

  const BookReaderScreen({
    super.key,
    required this.url,
    required this.title,
    required this.ebookId,
    this.initialPage = 1,
  });

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  late PdfViewerController _pdfController;
  late Future<Uint8List> _pdfFuture;
  int? lastPage;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();

    _pdfFuture = loadPdf();
    loadLastPage();
  }

  // 🔥 download PDF dulu
  Future<Uint8List> loadPdf() async {
    final response = await http.get(
      Uri.parse(widget.url),
      headers: {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/pdf'},
    );

    print("STATUS: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception("Gagal load PDF");
    }

    return response.bodyBytes;
  }

  Future<void> loadLastPage() async {
    final res = await ApiService.getReadingProgress(widget.ebookId);

    lastPage = res['data']['current_page'] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),

      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Gagal memuat PDF"));
          }

          return SfPdfViewer.memory(
            snapshot.data!,
            controller: _pdfController,

            onDocumentLoaded: (details) {
              if (lastPage != null && lastPage! > 0) {
                _pdfController.jumpToPage(lastPage!);
              }
            },

            onPageChanged: (details) {
              int currentPage = details.newPageNumber;
              int totalPage = _pdfController.pageCount;

              print("PAGE: $currentPage / $totalPage");

              if (totalPage == 0) return;

              double progress = currentPage / totalPage;

              print("SEND API: ${widget.ebookId}");

              ApiService.updateReadingProgress(
                widget.ebookId,
                progress,
                currentPage,
                totalPage,
              );
            },
          );
        },
      ),
    );
  }
}
