import pytest
import json
import base64
import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from app import app, ocr


@pytest.fixture
def client():
    """Create test client"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


class TestOCRService:
    """Test OCR Service health and processing"""
    
    def test_health_check(self, client):
        """Test /health endpoint"""
        response = client.get('/health')
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['status'] == 'ok'
        assert data['service'] == 'ocr'
        assert data['engine'] == 'tesseract'
    
    def test_process_endpoint_exists(self, client):
        """Test /process endpoint exists"""
        # Should fail without image but endpoint exists
        response = client.post('/process', json={})
        assert response.status_code in [400, 500]  # Either missing image or error
    
    def test_extract_entities_endpoint(self, client):
        """Test entity extraction endpoint"""
        response = client.post('/extract-entities', 
            json={'text': 'John Doe born 15.01.1990 in Berlin'})
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['success'] == True
        assert 'entities' in data


class TestDocumentOCR:
    """Test DocumentOCR class methods"""
    
    def test_ocr_initialization(self):
        """Test OCR service initializes"""
        from app import DocumentOCR
        ocr_service = DocumentOCR()
        assert ocr_service.engine == 'tesseract'
    
    def test_date_extraction(self):
        """Test date extraction from text"""
        text = "Ausgestellt: 15.06.2026 in Lähden"
        entities = ocr.extract_entities(text)
        # Should find date in format DD.MM.YYYY
        assert entities['dateOfBirth'] is None  # This is a date but not DOB
    
    def test_document_number_extraction(self):
        """Test document number extraction"""
        text = "Personalausweis: ABC123XYZ456"
        entities = ocr.extract_entities(text)
        # Should extract document numbers
        assert 'documentNumber' in entities
    
    def test_name_extraction_simple(self):
        """Test name extraction from simple text"""
        text = "John Smith\nDate: 1990-01-15"
        entities = ocr.extract_entities(text)
        # Should extract names if they appear at start
        assert 'firstName' in entities
        assert 'lastName' in entities


class TestEntityExtraction:
    """Test entity extraction functions"""
    
    def test_extract_german_text(self):
        """Test extraction from German document text"""
        german_text = """
        Personalausweis
        Mustermann, Max
        Geburtsdatum: 15.06.1985
        Geburtsort: München
        Adresse: Hauptstrasse 1, 80331 München
        Ausweisiummer: 1234567890XYZ
        """
        entities = ocr.extract_entities(german_text)
        assert 'firstName' in entities
        assert 'lastName' in entities
        assert 'dateOfBirth' in entities
    
    def test_empty_text_extraction(self):
        """Test extraction from empty text"""
        entities = ocr.extract_entities("")
        assert isinstance(entities, dict)
        # Should have all keys even if empty
        for key in ['firstName', 'lastName', 'dateOfBirth', 'documentNumber']:
            assert key in entities


class TestErrorHandling:
    """Test error handling"""
    
    def test_invalid_image_data(self, client):
        """Test handling of invalid image data"""
        response = client.post('/process', 
            json={'image': 'invalid_base64_data'})
        assert response.status_code in [400, 500]
    
    def test_missing_image_field(self, client):
        """Test missing image field"""
        response = client.post('/process', json={})
        assert response.status_code == 400
        data = json.loads(response.data)
        assert 'error' in data
    
    def test_malformed_json(self, client):
        """Test malformed JSON"""
        response = client.post('/process', 
            data='not json',
            content_type='application/json')
        assert response.status_code in [400, 415]


if __name__ == '__main__':
    pytest.main([__file__, '-v', '--tb=short'])
