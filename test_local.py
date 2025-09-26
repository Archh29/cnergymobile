#!/usr/bin/env python3
"""
Local test server for Flutter web app - No CSP conflicts
"""

import http.server
import socketserver
import os
import sys

class NoCSPHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Explicitly remove any CSP headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With')
        # Don't set any CSP headers - let HTML meta tag handle it
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

def main():
    web_dir = os.path.join(os.path.dirname(__file__), 'build', 'web')
    
    if not os.path.exists(web_dir):
        print(f"❌ Error: {web_dir} does not exist!")
        print("Please run 'flutter build web' first.")
        sys.exit(1)
    
    os.chdir(web_dir)
    
    PORT = 8080
    
    print("🚀 Starting Local Test Server (No CSP Conflicts)")
    print(f"📁 Serving from: {os.getcwd()}")
    print(f"🌐 Main app: http://localhost:{PORT}")
    print(f"🧪 CSP test: http://localhost:{PORT}/test_csp.html")
    print("⏹️  Press Ctrl+C to stop")
    print("-" * 60)
    
    with socketserver.TCPServer(("", PORT), NoCSPHTTPRequestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n🛑 Server stopped.")

if __name__ == "__main__":
    main()

