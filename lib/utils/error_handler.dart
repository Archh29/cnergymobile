import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ErrorHandler {
  static void handleError(dynamic error, StackTrace? stackTrace, {String? context}) {
    if (kDebugMode) {
      print('🚨 Error in $context: $error');
      if (stackTrace != null) {
        print('📍 Stack trace: $stackTrace');
      }
    }
    
    // Log to console for web debugging
    if (kIsWeb) {
      print('Web Error - Context: $context, Error: $error');
    }
  }
  
  static Widget buildErrorWidget(String message, {VoidCallback? onRetry}) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 64,
                ),
                SizedBox(height: 20),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4ECDC4),
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                    child: Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? context;
  final Widget Function(String error)? errorBuilder;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.context,
    this.errorBuilder,
  }) : super(key: key);

  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(errorMessage!);
      }
      return ErrorHandler.buildErrorWidget(
        errorMessage!,
        onRetry: () {
          setState(() {
            errorMessage = null;
          });
        },
      );
    }

    return widget.child;
  }

  void _handleError(dynamic error, StackTrace stackTrace) {
    ErrorHandler.handleError(error, stackTrace, context: widget.context);
    setState(() {
      errorMessage = error.toString();
    });
  }
}

// Global error handler for Flutter
void setupErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorHandler.handleError(
      details.exception,
      details.stack,
      context: 'Flutter Framework',
    );
  };
}
