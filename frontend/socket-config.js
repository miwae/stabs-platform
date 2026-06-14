    const connectSocket = () => {
      // Connect to Socket.io via Nginx proxy
      socket.value = io(window.location.origin, { 
        path: '/socket.io/',
        reconnection: true,
        reconnectionDelay: 1000,
        reconnectionDelayMax: 5000,
        reconnectionAttempts: 5
      });
      socket.value.on('connect', () => { 
        console.log('✅ Socket connected');
        connected.value = true; 
      });
      socket.value.on('disconnect', () => { 
        console.log('❌ Socket disconnected');
        connected.value = false; 
      });
      socket.value.on('connect_error', (error) => {
        console.error('Socket error:', error);
      });
    };