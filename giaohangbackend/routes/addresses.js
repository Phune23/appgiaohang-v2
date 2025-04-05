import express from 'express';
import pool from '../index.js';

const router = express.Router();

// Add new address or update existing address
router.post('/', async (req, res) => {
  try {
    const { userId, address, latitude, longitude } = req.body;
    
    // Validate userId
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    // Verify user exists
    const [users] = await pool.query('SELECT id FROM users WHERE id = ?', [userId]);
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    // Check if exact address already exists for this user
    const [existing] = await pool.query(
      'SELECT id FROM user_addresses WHERE user_id = ? AND address = ?',
      [userId, address]
    );

    let result;
    if (existing.length > 0) {
      // Update existing address
      [result] = await pool.query(
        'UPDATE user_addresses SET latitude = ?, longitude = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
        [latitude, longitude, existing[0].id]
      );
      res.status(200).json({
        message: 'Address updated successfully',
        addressId: existing[0].id
      });
    } else {
      // Insert new address
      [result] = await pool.query(
        'INSERT INTO user_addresses (user_id, address, latitude, longitude) VALUES (?, ?, ?, ?)',
        [userId, address, latitude, longitude]
      );
      res.status(201).json({
        message: 'Address saved successfully',
        addressId: result.insertId
      });
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user addresses
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const [addresses] = await pool.query(
      'SELECT * FROM user_addresses WHERE user_id = ?',
      [userId]
    );
    res.json(addresses);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update selected address
router.put('/select', async (req, res) => {
  try {
    const { userId, address } = req.body;
    
    // First, set all addresses for this user to not selected
    await pool.query(
      'UPDATE user_addresses SET is_selected = 0 WHERE user_id = ?',
      [userId]
    );

    // Then set the chosen address as selected
    const [result] = await pool.query(
      'UPDATE user_addresses SET is_selected = 1 WHERE user_id = ? AND address = ?',
      [userId, address]
    );

    if (result.affectedRows === 0) {
      res.status(404).json({ error: 'Address not found' });
      return;
    }

    res.json({ message: 'Selected address updated successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;