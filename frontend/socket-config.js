// Socket.io Configuration for Stabs-Platform Frontend

export const configureSocket = (app) => {
  const io = window.io;
  
  // Determine API URL dynamically
  const getApiUrl = () => {
    const protocol = window.location.protocol === 'https:' ? 'https:' : 'http:';
    const hostname = window.location.hostname;
    // API runs on port 3000, Frontend on 5173
    return `${protocol}//${hostname}:3000`;
  };

  const socket = io(getApiUrl(), {
    reconnection: true,
    reconnectionDelay: 1000,
    reconnectionDelayMax: 5000,
    reconnectionAttempts: 10,
    transports: ['websocket', 'polling']
  });

  socket.on('connect', () => {
    console.log('✅ Socket connected');
    if (app.$data) app.$data.connected = true;
  });

  socket.on('disconnect', () => {
    console.log('❌ Socket disconnected');
    if (app.$data) app.$data.connected = false;
  });

  socket.on('connect_error', (error) => {
    console.error('Socket connection error:', error);
  });

  socket.on('document:uploading', (data) => {
    console.log('Document uploading:', data);
  });

  socket.on('document:extracting', (data) => {
    console.log('Document extracting:', data);
  });

  return socket;
};

export default configureSocket;
