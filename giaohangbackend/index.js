import mysql from 'mysql2/promise';
import express from 'express';
import cors from 'cors';
import { createTables } from './database/tables.js';
import authRoutes from './routes/auth.js';
import storesRoutes from './routes/stores.js';
import foodsRoutes from './routes/foods.js';
import addressesRoutes from './routes/addresses.js';
import ordersRoutes from './routes/orders.js';
import usersRoutes from './routes/users.js';
import chatRoutes from './routes/chat.js';
import transactionsRoutes from './routes/transactions.js';
import earningsRoutes from './routes/earnings.js';
import agoraRoutes from './routes/agora.js';
import { Server } from 'socket.io';
import { createServer } from 'http';
import admin from 'firebase-admin';
import serviceAccount from './key/appgiaohangonline-firebase-adminsdk.json' assert { type: "json" };

// Initialize Firebase Admin before other initializations
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

//Cau hinh ket noi database
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: '', 
  database: 'giaohang_db'
};

const initializeDatabase = async () => {
  try {
    // First connect without database to create it if needed
    const connection = await mysql.createConnection({
      host: dbConfig.host,
      user: dbConfig.user,
      password: dbConfig.password
    });

    await connection.query(`CREATE DATABASE IF NOT EXISTS ${dbConfig.database}`);
    await connection.end();

    // Create connection pool with database selected
    const pool = mysql.createPool(dbConfig);
    
    // Test connection
    const [rows] = await pool.query('SELECT 1');
    console.log('Database connected successfully');
    
    // Initialize tables
    await createTables(pool);
    
    return pool;
  } catch (error) {
    console.error('Database connection failed:', error);
    throw error;
  }
};

// Initialize connection pool
const pool = await initializeDatabase();

const app = express();

// Configure CORS
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Accept', 'Authorization'],
  credentials: true,
  preflightContinue: false,
  optionsSuccessStatus: 204
}));

// Add headers middleware
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Accept, Authorization');
  
  // Handle preflight requests
  if (req.method === 'OPTIONS') {
    return res.status(204).send();
  }
  next();
});

app.use(express.json());

// Add logging middleware to debug routes
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Add more detailed logging middleware
app.use((req, res, next) => {
  console.log('Request:', {
    method: req.method,
    url: req.url,
    path: req.path,
    params: req.params,
    query: req.query
  });
  next();
});

// Register routes in correct order - users route should come before auth
app.use('/users', usersRoutes);
app.use('/auth', authRoutes);
app.use('/stores', storesRoutes);
app.use('/foods', foodsRoutes);
app.use('/addresses', addressesRoutes);
app.use('/orders', ordersRoutes);
app.use('/chat', chatRoutes);
app.use('/transactions', transactionsRoutes);
app.use('/earnings', earningsRoutes);
app.use('/agora', agoraRoutes);

// Update error handling middleware to exclude status-related errors
app.use((err, req, res, next) => {
  console.error('Error:', {
    method: req.method,
    url: req.url,
    error: err
  });
  
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(400).json({ 
      error: 'Email already registered' 
    });
  }
  
  res.status(500).json({ 
    error: err.message || 'Something went wrong!' 
  });
});

// Add 404 handler
app.use((req, res) => {
  console.log('404 for:', req.method, req.url);
  res.status(404).json({ error: 'Not found' });
});

// Move 404 handler to the end
const handle404 = (req, res) => {
  console.log('404 Not Found:', req.method, req.url);
  res.status(404).json({ error: 'Not found' });
};

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err);
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(400).json({ error: 'Email already registered' });
  }
  res.status(500).json({ error: err.message || 'Something went wrong!' });
});

// Add 404 handler last
app.use(handle404);

// Start server
const PORT = 3000;
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

io.on('connection', (socket) => {
  socket.on('join-delivery-room', (connectionString) => {
    socket.join(connectionString);
    console.log(connectionString);
  });

  socket.on('shipper-location', (data) => {
    io.to(data.connectionString).emit('location-update', {
      latitude: data.latitude,
      longitude: data.longitude,
    });
    // console.log(data.connectionString);
    // console.log(data.latitude , data.longitude);
  });

  // Handle chat room joining
  socket.on('join-chat', (orderId) => {
    socket.join(`chat-${orderId}`);
  });

  // Handle new messages
  socket.on('new-message', (message) => {
    io.to(`chat-${message.orderId}`).emit('message-received', message);
  });

  // Handle video calls
  socket.on('initiate-call', (data) => {
    // Forward call request to receiver
    io.emit(`call-to-${data.receiverId}`, {
      channelName: data.channelName,
      token: data.token,
      callerId: data.callerId,
      callerName: data.callerName
    });
  });

  socket.on('call-accepted', (data) => {
    // Notify caller that call was accepted
    io.emit(`call-accepted-${data.callerId}`, {
      channelName: data.channelName
    });
  });

  socket.on('call-rejected', (data) => {
    // Notify caller that call was rejected
    io.emit(`call-rejected-${data.callerId}`, {});
  });

  socket.on('end-call', (data) => {
    // Notify other participant that call ended
    io.emit(`call-ended-${data.receiverId}`, {});
  });
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

export default pool;
