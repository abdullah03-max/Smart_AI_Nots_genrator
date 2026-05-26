// lib/presentation/screens/notes/pdf_preview_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_theme.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfPreviewScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  String? _localPath;
  bool _isLoading = true;
  String _errorMessage = '';
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        
        // Generate a unique filename using a simple timestamp to prevent caching issues
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${dir.path}/temp_preview_$timestamp.pdf');
        
        await file.writeAsBytes(bytes, flush: true);
        if (mounted) {
          setState(() {
            _localPath = file.path;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load PDF (Server returned ${response.statusCode})';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error downloading PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_localPath != null && _totalPages > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryPurple),
                  const SizedBox(height: 16),
                  Text(
                    'Downloading document...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 64,
                          color: AppTheme.errorRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = '';
                            });
                            _downloadPdf();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _localPath == null
                  ? const Center(child: Text('Could not download PDF'))
                  : Stack(
                      children: [
                        PDFView(
                          filePath: _localPath,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                          pageSnap: true,
                          defaultPage: _currentPage,
                          fitPolicy: FitPolicy.BOTH,
                          preventLinkNavigation: false,
                          onRender: (pages) {
                            setState(() {
                              _totalPages = pages ?? 0;
                              _isReady = true;
                            });
                          },
                          onError: (error) {
                            setState(() {
                              _errorMessage = error.toString();
                            });
                          },
                          onPageError: (page, error) {
                            setState(() {
                              _errorMessage = error.toString();
                            });
                          },
                          onViewCreated: (PDFViewController pdfViewController) {
                            setState(() {
                              _pdfViewController = pdfViewController;
                            });
                          },
                          onPageChanged: (int? page, int? total) {
                            setState(() {
                              _currentPage = page ?? 0;
                            });
                          },
                        ),
                        if (!_isReady)
                          const Center(
                            child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                          ),
                      ],
                    ),
      floatingActionButton: _isReady && _totalPages > 1
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentPage > 0)
                  FloatingActionButton(
                    heroTag: 'prevPage',
                    mini: true,
                    onPressed: () {
                      _pdfViewController?.setPage(_currentPage - 1);
                    },
                    child: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                const SizedBox(width: 8),
                if (_currentPage < _totalPages - 1)
                  FloatingActionButton(
                    heroTag: 'nextPage',
                    mini: true,
                    onPressed: () {
                      _pdfViewController?.setPage(_currentPage + 1);
                    },
                    child: const Icon(Icons.arrow_forward_ios_rounded),
                  ),
              ],
            )
          : null,
    );
  }
}
