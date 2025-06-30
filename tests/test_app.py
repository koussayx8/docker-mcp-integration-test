#!/usr/bin/env python3
"""
Test suite for the Docker MCP integration application.
"""

import unittest
import requests
import time
import json
from unittest.mock import patch, MagicMock

# Assuming the app is running on localhost:8000
BASE_URL = "http://localhost:8000"

class TestApp(unittest.TestCase):
    """Test cases for the application."""
    
    @classmethod
    def setUpClass(cls):
        """Set up test environment."""
        cls.base_url = BASE_URL
        # Wait for the app to be ready
        cls.wait_for_app()
    
    @classmethod
    def wait_for_app(cls, timeout=30):
        """Wait for the application to be ready."""
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                response = requests.get(f"{cls.base_url}/health", timeout=5)
                if response.status_code == 200:
                    print("Application is ready for testing")
                    return
            except requests.exceptions.RequestException:
                pass
            time.sleep(1)
        raise Exception("Application did not start within timeout period")
    
    def test_home_page(self):
        """Test the home page."""
        response = requests.get(f"{self.base_url}/")
        self.assertEqual(response.status_code, 200)
        self.assertIn("Docker MCP Integration Test App", response.text)
    
    def test_health_endpoint(self):
        """Test the health check endpoint."""
        response = requests.get(f"{self.base_url}/health")
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertEqual(data['status'], 'healthy')
        self.assertIn('timestamp', data)
        self.assertIn('uptime', data)
        self.assertIn('version', data)
    
    def test_api_info_endpoint(self):
        """Test the API info endpoint."""
        response = requests.get(f"{self.base_url}/api/info")
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertIn('app_name', data)
        self.assertIn('version', data)
        self.assertIn('branch', data)
        self.assertIn('environment', data)
    
    def test_api_test_endpoint(self):
        """Test the API test endpoint."""
        response = requests.get(f"{self.base_url}/api/test")
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertEqual(data['test'], 'success')
        self.assertIn('message', data)
        self.assertIn('timestamp', data)
        self.assertIn('random_number', data)
    
    def test_metrics_endpoint(self):
        """Test the Prometheus metrics endpoint."""
        response = requests.get(f"{self.base_url}/metrics")
        self.assertEqual(response.status_code, 200)
        self.assertIn('app_requests_total', response.text)
    
    def test_404_handling(self):
        """Test 404 error handling."""
        response = requests.get(f"{self.base_url}/nonexistent")
        self.assertEqual(response.status_code, 404)
        
        data = response.json()
        self.assertIn('error', data)
    
    def test_concurrent_requests(self):
        """Test handling of concurrent requests."""
        import concurrent.futures
        
        def make_request():
            return requests.get(f"{self.base_url}/api/test")
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
            futures = [executor.submit(make_request) for _ in range(20)]
            results = [future.result() for future in concurrent.futures.as_completed(futures)]
        
        # All requests should be successful
        for response in results:
            self.assertEqual(response.status_code, 200)
    
    def test_response_time(self):
        """Test response time is reasonable."""
        start_time = time.time()
        response = requests.get(f"{self.base_url}/api/test")
        end_time = time.time()
        
        self.assertEqual(response.status_code, 200)
        self.assertLess(end_time - start_time, 1.0)  # Should respond within 1 second

class TestAppUnit(unittest.TestCase):
    """Unit tests for the application."""
    
    def test_app_import(self):
        """Test that the app can be imported."""
        try:
            import sys
            import os
            sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))
            import app
            self.assertTrue(hasattr(app, 'app'))
        except ImportError as e:
            self.fail(f"Failed to import app: {e}")

def run_tests():
    """Run all tests and return results."""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test classes
    suite.addTests(loader.loadTestsFromTestCase(TestApp))
    suite.addTests(loader.loadTestsFromTestCase(TestAppUnit))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Return success status
    return result.wasSuccessful()

if __name__ == '__main__':
    success = run_tests()
    exit(0 if success else 1)
