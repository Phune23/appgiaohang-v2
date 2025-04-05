import express from 'express';
import pool from '../index.js';
import bcrypt from 'bcrypt';

const router = express.Router();

// Debug middleware for users routes
router.use((req, res, next) => {
  console.log(`[Users] ${req.method} ${req.url}`);
  next();
});

// Get all users
router.get('/', async (req, res) => {
  try {
    const [users] = await pool.query(
      'SELECT id, email, full_name, phone_number, role, is_active, created_at FROM users'
    );
    res.json({ users });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user active status
router.put('/:id/active', async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;
    
    const [result] = await pool.query(
      'UPDATE users SET is_active = ? WHERE id = ?',
      [isActive, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ message: 'User active status updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create new user by admin
router.post('/', async (req, res) => {
  try {
    console.log('Create user request body:', req.body); // Add debug log
    const { email, password, fullName, phoneNumber, role } = req.body;
    
    if (!email || !password || !fullName || !phoneNumber || !role) {
      return res.status(400).json({ 
        error: 'All fields are required' 
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    const [result] = await pool.query(
      'INSERT INTO users (email, password, full_name, phone_number, role) VALUES (?, ?, ?, ?, ?)',
      [email, hashedPassword, fullName, phoneNumber, role]
    );

    res.status(201).json({ 
      message: 'User created successfully',
      userId: result.insertId 
    });
  } catch (error) {
    console.error('Create user error:', error); // Add debug log
    res.status(500).json({ error: error.message });
  }
});

// Update user information
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { fullName, phoneNumber, role } = req.body;
    
    const [result] = await pool.query(
      'UPDATE users SET full_name = ?, phone_number = ?, role = ? WHERE id = ?',
      [fullName, phoneNumber, role, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ message: 'User updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
