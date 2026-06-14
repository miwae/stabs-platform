<template>
  <div class="polygon-drawer">
    <div class="controls">
      <button 
        @click="toggleDraw" 
        :class="{ active: isDrawing }"
        class="btn btn-primary"
      >
        {{ isDrawing ? '✓ Drawing' : '✎ Draw Polygon' }}
      </button>
      
      <button 
        @click="savePolygon" 
        :disabled="!isDrawing || coordinates.length < 3"
        class="btn btn-success"
      >
        💾 Save
      </button>
      
      <button 
        @click="clearDraw" 
        :disabled="!isDrawing"
        class="btn btn-warning"
      >
        🗑️ Clear
      </button>
    </div>

    <div class="coordinates-list" v-if="coordinates.length > 0">
      <h4>Coordinates ({{ coordinates.length }})</h4>
      <div class="coords">
        <div v-for="(coord, idx) in coordinates" :key="idx" class="coord-item">
          {{ idx + 1 }}. {{ coord.lat.toFixed(4) }}, {{ coord.lng.toFixed(4) }}
          <button @click="removeCoordinate(idx)" class="btn-small">✕</button>
        </div>
      </div>
    </div>

    <div v-if="error" class="alert alert-error">{{ error }}</div>
    <div v-if="success" class="alert alert-success">{{ success }}</div>
  </div>
</template>

<script>
import { ref, inject, onMounted, watch } from 'vue';

export default {
  name: 'PolygonDrawer',
  props: {
    incidentId: {
      type: String,
      required: true
    },
    map: {
      type: Object,
      required: true
    }
  },
  emits: ['polygon-saved'],
  setup(props, { emit }) {
    const isDrawing = ref(false);
    const coordinates = ref([]);
    const drawnPolygon = ref(null);
    const error = ref('');
    const success = ref('');
    const saving = ref(false);

    const toggleDraw = () => {
      isDrawing.value = !isDrawing.value;
      if (!isDrawing.value) {
        clearDraw();
      }
    };

    const clearDraw = () => {
      coordinates.value = [];
      if (drawnPolygon.value) {
        props.map.removeLayer(drawnPolygon.value);
        drawnPolygon.value = null;
      }
      error.value = '';
    };

    const addCoordinate = (lat, lng) => {
      coordinates.value.push({ lat, lng });
      updatePolygonOnMap();
    };

    const removeCoordinate = (idx) => {
      coordinates.value.splice(idx, 1);
      updatePolygonOnMap();
    };

    const updatePolygonOnMap = () => {
      if (drawnPolygon.value) {
        props.map.removeLayer(drawnPolygon.value);
      }

      if (coordinates.value.length >= 2) {
        const latlngs = coordinates.value.map(c => [c.lat, c.lng]);
        drawnPolygon.value = L.polyline(latlngs, {
          color: 'blue',
          weight: 2,
          opacity: 0.8,
          dashArray: '5, 5'
        }).addTo(props.map);
      }
    };

    const savePolygon = async () => {
      if (coordinates.value.length < 3) {
        error.value = 'Mindestens 3 Punkte erforderlich!';
        return;
      }

      saving.value = true;
      error.value = '';
      success.value = '';

      try {
        const res = await fetch('/api/polygons', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            incident_id: props.incidentId,
            coordinates: coordinates.value,
            type: 'operational_area'
          })
        });

        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.error || 'Save failed');
        }

        success.value = `✓ Polygon gespeichert (ID: ${data.id})`;
        clearDraw();
        emit('polygon-saved', data);
      } catch (err) {
        error.value = `❌ Fehler: ${err.message}`;
      } finally {
        saving.value = false;
      }
    };

    // Click auf Karte um Punkt hinzuzufügen
    const handleMapClick = (e) => {
      if (isDrawing.value) {
        addCoordinate(e.latlng.lat, e.latlng.lng);
      }
    };

    onMounted(() => {
      if (props.map) {
        props.map.on('click', handleMapClick);
      }
    });

    return {
      isDrawing,
      coordinates,
      error,
      success,
      saving,
      toggleDraw,
      clearDraw,
      removeCoordinate,
      savePolygon
    };
  }
};
</script>

<style scoped>
.polygon-drawer {
  background: white;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  font-family: Arial, sans-serif;
}

.controls {
  display: flex;
  gap: 10px;
  margin-bottom: 15px;
  flex-wrap: wrap;
}

.btn {
  padding: 8px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.3s;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-primary:hover {
  background: #0056b3;
}

.btn-primary.active {
  background: #28a745;
  animation: pulse 0.6s infinite;
}

.btn-success {
  background: #28a745;
  color: white;
}

.btn-success:hover:not(:disabled) {
  background: #1e7e34;
}

.btn-warning {
  background: #ffc107;
  color: black;
}

.btn-warning:hover:not(:disabled) {
  background: #e0a800;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-small {
  padding: 2px 6px;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
  font-size: 12px;
}

.btn-small:hover {
  background: #c82333;
}

.coordinates-list {
  margin-top: 15px;
}

.coordinates-list h4 {
  margin: 0 0 10px 0;
  color: #333;
}

.coords {
  max-height: 200px;
  overflow-y: auto;
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 10px;
  background: #f9f9f9;
}

.coord-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 5px;
  font-size: 12px;
  font-family: monospace;
  border-bottom: 1px solid #eee;
}

.coord-item:last-child {
  border-bottom: none;
}

.alert {
  padding: 12px;
  border-radius: 4px;
  margin-top: 10px;
  font-size: 14px;
}

.alert-error {
  background: #f8d7da;
  border: 1px solid #f5c6cb;
  color: #721c24;
}

.alert-success {
  background: #d4edda;
  border: 1px solid #c3e6cb;
  color: #155724;
}

@keyframes pulse {
  0%, 100% {
    box-shadow: 0 0 0 0 rgba(40, 167, 69, 0.7);
  }
  50% {
    box-shadow: 0 0 0 10px rgba(40, 167, 69, 0);
  }
}
</style>
