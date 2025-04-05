
import express from 'express';
import pool from '../index.js';

const router = express.Router();

// Get chat messages for an order
router.get('/:orderId', async (req, res) => {
  try {
    const [messages] = await pool.query(
      `SELECT 
        m.*,
        u.full_name as sender_name
      FROM chat_messages m
      JOIN users u ON m.sender_id = u.id
      WHERE m.order_id = ?
      ORDER BY m.created_at ASC`,
      [req.params.orderId]
    );
    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send new message
router.post('/', async (req, res) => {
  try {
    const { orderId, senderId, receiverId, message } = req.body;
    const [result] = await pool.query(
      `INSERT INTO chat_messages (order_id, sender_id, receiver_id, message) 
       VALUES (?, ?, ?, ?)`,
      [orderId, senderId, receiverId, message]
    );
    res.status(201).json({ id: result.insertId });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;