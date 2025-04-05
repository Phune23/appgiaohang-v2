
import express from 'express';
import pool from '../index.js';

const router = express.Router();

// Get user balance
router.get('/balance/:userId', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT balance FROM users WHERE id = ?',
      [req.params.userId]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json({ balance: rows[0].balance });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add money to balance
router.post('/deposit', async (req, res) => {
  const { userId, amount } = req.body;
  const conn = await pool.getConnection();
  
  try {
    await conn.beginTransaction();
    
    // Update user balance
    await conn.query(
      'UPDATE users SET balance = balance + ? WHERE id = ?',
      [amount, userId]
    );
    
    // Record transaction
    await conn.query(
      'INSERT INTO transactions (user_id, amount, type, description) VALUES (?, ?, "deposit", "Deposit money")',
      [userId, amount]
    );
    
    await conn.commit();
    res.json({ message: 'Deposit successful' });
  } catch (error) {
    await conn.rollback();
    res.status(500).json({ error: error.message });
  } finally {
    conn.release();
  }
});

// Get transaction history
router.get('/history/:userId', async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT * FROM transactions WHERE user_id = ? ORDER BY created_at DESC',
      [req.params.userId]
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;