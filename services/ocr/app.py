#!/usr/bin/env python3
"""
Python OCR Service
Offline document processing with Tesseract
"""

import os
import cv2
import pytesseract
import numpy as np
from PIL import Image
from flask import Flask, request, jsonify
from flask_cors import CORS
from io import BytesIO
import base64
import logging
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Tesseract config for German text
TESSERACT_CONFIG = '--oem 3 --psm 6 -l deu'

class DocumentOCR:
    """OCR Service for document processing"""
    
    def __init__(self):
        self.engine = 'tesseract'
        logger.info("OCR Service initialized with Tesseract")
    
    def preprocess_image(self, image_data):
        """Optimize image for OCR"""
        try:
            # Convert bytes to image
            if isinstance(image_data, str):
                image_data = base64.b64decode(image_data)
            
            img = cv2.imdecode(np.frombuffer(image_data, np.uint8), cv2.IMREAD_COLOR)
            
            # Convert to grayscale
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            # Denoise
            denoised = cv2.fastNlMeansDenoising(gray, h=10)
            
            # Enhance contrast
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            enhanced = clahe.apply(denoised)
            
            logger.info("Image preprocessing completed")
            return enhanced
        
        except Exception as e:
            logger.error(f"Preprocessing error: {str(e)}")
            raise
    
    def extract_text(self, image_data):
        """Extract text from document image"""
        try:
            processed = self.preprocess_image(image_data)
            
            # Run Tesseract
            text = pytesseract.image_to_string(processed, config=TESSERACT_CONFIG)
            
            # Get confidence scores
            data = pytesseract.image_to_data(
                processed,
                config=TESSERACT_CONFIG,
                output_type=pytesseract.Output.DICT
            )
            
            confidences = [int(c) for c in data['conf'] if c != '-1']
            avg_confidence = np.mean(confidences) / 100 if confidences else 0
            
            logger.info(f"OCR extraction completed. Confidence: {avg_confidence:.2%}")
            
            return {
                'text': text,
                'confidence': avg_confidence,
                'language': 'deu'
            }
        
        except Exception as e:
            logger.error(f"Text extraction error: {str(e)}")
            raise
    
    def extract_entities(self, text):
        """Extract structured entities from OCR text"""
        import re
        
        entities = {
            'firstName': self._extract_name(text, 'first'),
            'lastName': self._extract_name(text, 'last'),
            'dateOfBirth': self._extract_date(text),
            'birthPlace': self._extract_place(text),
            'address': self._extract_address(text),
            'documentNumber': self._extract_doc_number(text),
            'issueDate': self._extract_issue_date(text),
            'expiryDate': self._extract_expiry_date(text),
        }
        
        logger.info(f"Entity extraction completed")
        return entities
    
    def _extract_date(self, text):
        """Extract date in DD.MM.YYYY format"""
        import re
        pattern = r'(\d{1,2})\.(\d{1,2})\.(\d{4})'
        match = re.search(pattern, text)
        return match.group(0) if match else None
    
    def _extract_name(self, text, pos):
        """Extract first or last name"""
        lines = text.split('\n')
        for line in lines[:10]:
            words = line.split()
            if len(words) > 0 and words[0][0].isupper():
                if pos == 'first' and len(words) > 0:
                    return words[0]
                elif pos == 'last' and len(words) > 1:
                    return words[1]
        return None
    
    def _extract_place(self, text):
        """Extract place"""
        return None  # Placeholder
    
    def _extract_address(self, text):
        """Extract address"""
        return None  # Placeholder
    
    def _extract_doc_number(self, text):
        """Extract document number"""
        import re
        pattern = r'\b[A-Z0-9]{8,12}\b'
        match = re.search(pattern, text)
        return match.group(0) if match else None
    
    def _extract_issue_date(self, text):
        """Extract issue date"""
        return None  # Placeholder
    
    def _extract_expiry_date(self, text):
        """Extract expiry date"""
        return None  # Placeholder


# Initialize OCR service
ocr = DocumentOCR()

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'service': 'ocr',
        'engine': ocr.engine,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/process', methods=['POST'])
def process_document():
    """Process document image"""
    try:
        data = request.json
        
        if 'image' not in data:
            return jsonify({'error': 'Missing image data'}), 400
        
        image_data = data['image']
        
        # Extract text
        ocr_result = ocr.extract_text(image_data)
        
        # Extract entities
        entities = ocr.extract_entities(ocr_result['text'])
        
        return jsonify({
            'success': True,
            'ocr_text': ocr_result['text'],
            'confidence': ocr_result['confidence'],
            'entities': entities,
            'language': ocr_result['language']
        })
    
    except Exception as e:
        logger.error(f"Processing error: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/extract-entities', methods=['POST'])
def extract_entities():
    """Extract entities from text"""
    try:
        data = request.json
        text = data.get('text', '')
        
        if not text:
            return jsonify({'error': 'Missing text'}), 400
        
        entities = ocr.extract_entities(text)
        
        return jsonify({
            'success': True,
            'entities': entities
        })
    
    except Exception as e:
        logger.error(f"Entity extraction error: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    logger.info("🚀 OCR Service starting...")
    app.run(host='0.0.0.0', port=5000, debug=True)
