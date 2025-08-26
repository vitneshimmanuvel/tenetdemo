import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

class DocumentViewer extends StatefulWidget {
  final String documentUrl;
  final String documentName;
  final String? documentType;

  const DocumentViewer({
    super.key,
    required this.documentUrl,
    required this.documentName,
    this.documentType,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  late String _fileType;
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _determineFileType();
  }

  void _determineFileType() {
    if (widget.documentType != null && widget.documentType!.isNotEmpty) {
      _fileType = widget.documentType!.toUpperCase();
    } else {
      final extension = path.extension(widget.documentUrl).toLowerCase();
      _fileType = _getFileTypeFromExtension(extension);
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _getFileTypeFromExtension(String extension) {
    switch (extension) {
      case '.pdf':
        return 'PDF';
      case '.jpg':
      case '.jpeg':
        return 'JPEG';
      case '.png':
        return 'PNG';
      case '.gif':
        return 'GIF';
      case '.bmp':
        return 'BMP';
      case '.webp':
        return 'WEBP';
      case '.doc':
      case '.docx':
        return 'DOC';
      case '.xls':
      case '.xlsx':
        return 'XLS';
      case '.ppt':
      case '.pptx':
        return 'PPT';
      case '.txt':
        return 'TXT';
      default:
        return 'FILE';
    }
  }

  // ✅ FIXED: Proper Cloudinary URL handling for PDFs
  String _getOptimizedUrl(String originalUrl) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    // For PDFs, we need to ensure inline viewing, not forced download
    if (_fileType == 'PDF') {
      // Remove any existing fl_attachment parameters that force downloads
      String cleanUrl = originalUrl.replaceAll(RegExp(r'/fl_attachment[^/]*'), '');

      // Ensure the URL has proper format for inline viewing
      if (!cleanUrl.contains('/fl_immutable_cache')) {
        final baseUrl = cleanUrl.split('/upload/')[0];
        final pathPart = cleanUrl.split('/upload/')[1];

        // Add parameters for better PDF handling without forcing download
        cleanUrl = '$baseUrl/upload/f_auto,q_auto/$pathPart';
      }

      print('🔍 Optimized PDF URL: $cleanUrl');
      return cleanUrl;
    }

    return originalUrl;
  }

  bool _isDirectlyViewable(String fileType) {
    return ['PDF', 'JPEG', 'JPG', 'PNG', 'GIF', 'BMP', 'WEBP'].contains(fileType);
  }

  bool _isImageFile(String fileType) {
    return ['JPEG', 'JPG', 'PNG', 'GIF', 'BMP', 'WEBP'].contains(fileType);
  }

  bool _isPdfFile(String fileType) {
    return fileType == 'PDF';
  }

  bool _isOfficeDocument(String fileType) {
    return ['DOC', 'XLS', 'PPT', 'TXT'].contains(fileType);
  }

  Color _getFileColor(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Colors.red[600]!;
      case 'JPEG':
      case 'JPG':
      case 'PNG':
      case 'GIF':
      case 'BMP':
      case 'WEBP':
        return Colors.blue[600]!;
      case 'DOC':
        return Colors.indigo[600]!;
      case 'XLS':
        return Colors.green[600]!;
      case 'PPT':
        return Colors.orange[600]!;
      case 'TXT':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType) {
      case 'PDF':
        return Icons.picture_as_pdf;
      case 'DOC':
        return Icons.description;
      case 'XLS':
        return Icons.table_chart;
      case 'PPT':
        return Icons.slideshow;
      case 'TXT':
        return Icons.text_snippet;
      case 'JPEG':
      case 'JPG':
      case 'PNG':
      case 'GIF':
      case 'BMP':
      case 'WEBP':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _openExternally() async {
    try {
      final uri = Uri.parse(widget.documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSuccessSnackBar('Opening in external app...');
      } else {
        _showErrorSnackBar('Cannot open this document type externally');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to open document: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _isDirectlyViewable(_fileType)
                  ? 'Viewable in app'
                  : 'External app required',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: _getFileColor(_fileType),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open in External App',
          ),
          IconButton(
            onPressed: () async {
              try {
                final uri = Uri.parse(widget.documentUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                _showSuccessSnackBar('Download started');
              } catch (e) {
                _showErrorSnackBar('Failed to download document');
              }
            },
            icon: const Icon(Icons.download),
            tooltip: 'Download',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildDocumentView(),
    );
  }

  Widget _buildDocumentView() {
    if (_isPdfFile(_fileType)) {
      return _buildPdfViewer();
    } else if (_isImageFile(_fileType)) {
      return _buildImageViewer();
    } else {
      return _buildUnsupportedFileView();
    }
  }

  // ✅ FIXED: PDF Viewer with better error handling and proper headers
  Widget _buildPdfViewer() {
    final optimizedUrl = _getOptimizedUrl(widget.documentUrl);

    print('🔍 Loading PDF from URL: $optimizedUrl');

    return Container(
      padding: const EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SfPdfViewer.network(
            optimizedUrl,
            key: _pdfViewerKey,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            // ✅ FIXED: Better headers for PDF loading
            headers: const {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
              'Accept': 'application/pdf,*/*',
              'Accept-Encoding': 'gzip, deflate, br',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              print('❌ PDF Load Failed: ${details.error}');
              print('❌ PDF URL: $optimizedUrl');
              print('❌ Description: ${details.description}');

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _errorMessage = 'Failed to load PDF: ${details.description}\nTry opening externally.';
                  });
                }
              });
            },
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              print('✅ PDF Loaded: ${details.document.pages.count} pages');
              _showSuccessSnackBar('PDF loaded successfully (${details.document.pages.count} pages)');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.documentUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    padding: const EdgeInsets.all(64),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading image...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openExternally,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open External'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnsupportedFileView() {
    final color = _getFileColor(_fileType);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Icon(
                    _getFileIcon(_fileType),
                    size: 64,
                    color: color,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '$_fileType Document',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.documentName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isOfficeDocument(_fileType)
                            ? 'Office documents require external apps like Microsoft Office, Google Docs, or WPS Office to view.'
                            : 'This document type cannot be previewed internally.\nUse external app to view the document.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _openExternally,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(_isOfficeDocument(_fileType)
                          ? 'Open in Office App'
                          : 'Open External App'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(widget.documentUrl);
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                          _showSuccessSnackBar('Download started');
                        } catch (e) {
                          _showErrorSnackBar('Failed to download document');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Document',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _openExternally,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getFileColor(_fileType),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open External'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
