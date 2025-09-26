#!/usr/bin/env python3
"""
Simple HTTP server for testing Flutter web app locally
This server serves the build/web directory with proper headers
"""

import http.server
import socketserver
import os
import sys

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Remove any CSP headers that might interfere
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With')
        super().end_headers()

    def do_OPTIONS(self):
        # Handle preflight requests
        self.send_response(200)
        self.end_headers()

def main():
    # Change to the build/web directory
    web_dir = os.path.join(os.path.dirname(__file__), 'build', 'web')
    
    if not os.path.exists(web_dir):
        print(f"Error: {web_dir} does not exist!")
        print("Please run 'flutter build web' first.")
        sys.exit(1)
    
    os.chdir(web_dir)
    
    PORT = 8000
    
    print(f"🚀 Serving CNERGY Flutter Web App at http://localhost:{PORT}")
    print(f"📁 Serving from: {os.getcwd()}")
    print("🔧 CSP is configured to be permissive for development")
    print("⏹️  Press Ctrl+C to stop the server")
    print("-" * 50)
    
    with socketserver.TCPServer(("", PORT), CustomHTTPRequestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped.")

if __name__ == "__main__":
    main()

