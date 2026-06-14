<template>
  <div class="document-scanner">
    <div class="header">
      <h1>📄 Document Scanner</h1>
      <p>Scan ID documents and extract data automatically</p>
    </div>

    <!-- File Upload Section -->
    <div class="upload-section">
      <div class="upload-area" @dragover="dragover = true" @dragleave="dragover = false" @drop="handleDrop">
        <input 
          type="file" 
          ref="fileInput" 
          @change="onFileSelected" 
          accept="image/*"
          hidden
        />
        
        <div v-if="!previewImage" class="upload-prompt">
          <p class="icon">📸</p>
          <p>Drag and drop or click to upload</p>
          <button @click="$refs.fileInput.click()" class="btn-primary">
            Choose File
          </button>
        </div>

        <div v-if="previewImage" class="preview">
          <img :src="previewImage" alt="Preview" />
          <button @click="clearPreview" class="btn-secondary">Change File</button>
        </div>
      </div>
    </div>

    <!-- Processing Status -->
    <div v-if="processing" class="processing">
      <div class="spinner"></div>
      <p>Processing document...</p>
      <p class="confidence-text">{{ processingProgress }}%</p>
    </div>

    <!-- Extracted Data Form -->
    <div v-if="extractedData && !processing" class="extracted-section">
      <h2>Extracted Information</h2>
      
      <div class="form-grid">
        <div class="form-group">
          <label>First Name</label>
          <div class="input-wrapper">
            <input v-model="extractedData.firstName" type="text" />
            <span class="confidence">{{ extractedData.confidence?.firstName || 0 }}%</span>
          </div>
        </div>

        <div class="form-group">
          <label>Last Name</label>
          <div class="input-wrapper">
            <input v-model="extractedData.lastName" type="text" />
            <span class="confidence">{{ extractedData.confidence?.lastName || 0 }}%</span>
          </div>
        </div>

        <div class="form-group">
          <label>Date of Birth</label>
          <div class="input-wrapper">
            <input v-model="extractedData.dateOfBirth" type="date" />
            <span class="confidence">{{ extractedData.confidence?.dateOfBirth || 0 }}%</span>
          </div>
        </div>

        <div class="form-group">
          <label>Birth Place</label>
          <div class="input-wrapper">
            <input v-model="extractedData.birthPlace" type="text" />
            <span class="confidence">{{ extractedData.confidence?.birthPlace || 0 }}%</span>
          </div>
        </div>

        <div class="form-group full-width">
          <label>Address</label>
          <div class="input-wrapper">
            <textarea v-model="extractedData.address" rows="2"></textarea>
            <span class="confidence">{{ extractedData.confidence?.address || 0 }}%</span>
          </div>
        </div>

        <div class="form-group">
          <label>Document Number</label>
          <div class="input-wrapper">
            <input v-model="extractedData.documentNumber" type="text" />
            <span class="confidence">{{ extractedData.confidence?.documentNumber || 0 }}%</span>
          </div>
        </div>
      </div>

      <!-- Duplicate Detection -->
      <div v-if="potentialDuplicates.length > 0" class="duplicates-section">
        <h3>⚠️ Potential Duplicates Found</h3>
        <div class="duplicates-list">
          <div v-for="dup in potentialDuplicates" :key="dup.id" class="duplicate-item">
            <p><strong>{{ dup.firstName }} {{ dup.lastName }}</strong></p>
            <p>DOB: {{ dup.dateOfBirth }}</p>
            <p class="similarity">Similarity: {{ (dup.similarity * 100).toFixed(0) }}%</p>
            <button @click="mergeDuplicate(dup.id)" class="btn-secondary">Merge</button>
          </div>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="action-buttons">
        <button @click="generatePDF" class="btn-primary">
          📄 Generate PDF
        </button>
        <button @click="saveRegistration" class="btn-primary">
          💾 Save Registration
        </button>
        <button @click="clearAll" class="btn-secondary">
          Clear All
        </button>
      </div>
    </div>

    <!-- Error Display -->
    <div v-if="error" class="error-message">
      <p>❌ {{ error }}</p>
      <button @click="error = null">Dismiss</button>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';

const fileInput = ref(null);
const previewImage = ref(null);
const processing = ref(false);
const processingProgress = ref(0);
const error = ref(null);
const dragover = ref(false);

const extractedData = reactive({
  firstName: '',
  lastName: '',
  dateOfBirth: '',
  birthPlace: '',
  address: '',
  documentNumber: '',
  confidence: {},
});

const potentialDuplicates = ref([]);

const onFileSelected = async (event) => {
  const file = event.target.files[0];
  if (!file) return;

  // Create preview
  const reader = new FileReader();
  reader.onload = (e) => {
    previewImage.value = e.target.result;
  };
  reader.readAsDataURL(file);

  // Process with OCR
  await processDocument(file);
};

const handleDrop = (event) => {
  event.preventDefault();
  dragover.value = false;
  const files = event.dataTransfer.files;
  if (files.length > 0) {
    fileInput.value.files = files;
    onFileSelected({ target: { files } });
  }
};

const processDocument = async (file) => {
  processing.value = true;
  processingProgress.value = 0;

  try {
    const formData = new FormData();
    formData.append('file', file);

    // Simulate progress
    const progressInterval = setInterval(() => {
      processingProgress.value = Math.min(processingProgress.value + 15, 90);
    }, 300);

    // Call API
    const response = await fetch('http://localhost:3000/api/documents/upload', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: formData
    });

    clearInterval(progressInterval);
    processingProgress.value = 100;

    if (!response.ok) throw new Error('Upload failed');

    const result = await response.json();
    
    // Mock extracted data (in real implementation, would come from backend)
    Object.assign(extractedData, {
      firstName: 'John',
      lastName: 'Doe',
      dateOfBirth: '1990-01-15',
      confidence: {
        firstName: 98,
        lastName: 96,
        dateOfBirth: 95
      }
    });

    // Check for duplicates
    await checkDuplicates();

  } catch (e) {
    error.value = e.message;
  } finally {
    processing.value = false;
  }
};

const checkDuplicates = async () => {
  try {
    const response = await fetch('http://localhost:3000/api/persons/search', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify(extractedData)
    });

    if (response.ok) {
      potentialDuplicates.value = await response.json();
    }
  } catch (e) {
    console.error('Duplicate check error:', e);
  }
};

const generatePDF = async () => {
  try {
    const response = await fetch('http://localhost:3000/api/registrations/pdf', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify(extractedData)
    });

    const blob = await response.blob();
    const url = URL.createObjectURL(blob);
    window.open(url, '_blank');
  } catch (e) {
    error.value = 'PDF generation failed';
  }
};

const saveRegistration = async () => {
  try {
    const response = await fetch('http://localhost:3000/api/registrations/create', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${localStorage.getItem('token')}`
      },
      body: JSON.stringify(extractedData)
    });

    if (response.ok) {
      error.value = null;
      alert('Registration saved successfully!');
      clearAll();
    }
  } catch (e) {
    error.value = 'Save failed: ' + e.message;
  }
};

const mergeDuplicate = (duplicateId) => {
  console.log('Merging with:', duplicateId);
  // TODO: Implement merge logic
};

const clearPreview = () => {
  previewImage.value = null;
  fileInput.value.value = '';
};

const clearAll = () => {
  clearPreview();
  Object.assign(extractedData, {
    firstName: '',
    lastName: '',
    dateOfBirth: '',
    birthPlace: '',
    address: '',
    documentNumber: '',
    confidence: {}
  });
  potentialDuplicates.value = [];
  error.value = null;
};
</script>

<style scoped>
.document-scanner {
  max-width: 900px;
  margin: 0 auto;
  padding: 2rem;
}

.header {
  text-align: center;
  margin-bottom: 2rem;
}

.header h1 {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.upload-section {
  margin-bottom: 2rem;
}

.upload-area {
  border: 2px dashed #ccc;
  border-radius: 8px;
  padding: 2rem;
  text-align: center;
  transition: all 0.3s;
  cursor: pointer;
}

.upload-area:hover,
.upload-area.dragover {
  border-color: #007bff;
  background: #f0f8ff;
}

.upload-prompt .icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.preview img {
  max-width: 100%;
  max-height: 400px;
  border-radius: 8px;
  margin-bottom: 1rem;
}

.processing {
  text-align: center;
  padding: 2rem;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #007bff;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.confidence-text {
  font-weight: bold;
  color: #007bff;
}

.extracted-section {
  background: #f9f9f9;
  padding: 2rem;
  border-radius: 8px;
  margin-bottom: 2rem;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.form-group.full-width {
  grid-column: 1 / -1;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.input-wrapper {
  position: relative;
  display: flex;
  gap: 0.5rem;
}

.input-wrapper input,
.input-wrapper textarea {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.confidence {
  background: #e8f4f8;
  padding: 0.75rem;
  border-radius: 4px;
  min-width: 60px;
  text-align: center;
  font-size: 0.85rem;
  color: #666;
}

.duplicates-section {
  background: #fff3cd;
  padding: 1.5rem;
  border-radius: 8px;
  margin-bottom: 2rem;
  border-left: 4px solid #ffc107;
}

.duplicates-list {
  margin-top: 1rem;
}

.duplicate-item {
  background: white;
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 0.5rem;
}

.similarity {
  color: #856404;
  font-size: 0.85rem;
}

.action-buttons {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}

.btn-primary,
.btn-secondary {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-primary:hover {
  background: #0056b3;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #545b62;
}

.error-message {
  background: #f8d7da;
  color: #721c24;
  padding: 1rem;
  border-radius: 4px;
  margin-top: 1rem;
  border-left: 4px solid #f5c6cb;
}
</style>
