import express from 'express';
import pool from '../index.js';

const router = express.Router();

// Create new store
router.post('/', async (req, res) => {
  try {
    const { name, address, phone_number, owner_id, latitude, longitude } = req.body;
    const [result] = await pool.query(
      'INSERT INTO food_stores (name, address, phone_number, owner_id, status, latitude, longitude) VALUES (?, ?, ?, ?, "pending", ?, ?)',
      [name, address, phone_number, owner_id, latitude, longitude]
    );
    res.status(201).json({ 
      id: result.insertId,
      name,
      address,
      phone_number,
      owner_id,
      status: 'pending',
      latitude,
      longitude
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update store
router.put('/:id', async (req, res) => {
  try {
    const { name, address, phone_number } = req.body;
    await pool.query(
      'UPDATE food_stores SET name = ?, address = ?, phone_number = ? WHERE id = ?',
      [name, address, phone_number, req.params.id]
    );
    res.json({ id: req.params.id, ...req.body });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.patch('/:id/status', async (req, res) => {
  try {
    const { is_active } = req.body;
    await pool.query(
      'UPDATE food_stores SET is_active = ? WHERE id = ?',
      [is_active, req.params.id]
    );
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/user', async (req, res) => {
  try {
    const [stores] = await pool.query(
      'SELECT * FROM food_stores WHERE status = "approved" AND is_active = true'
    );
    console.log('Fetched approved stores:', stores);
    res.json(stores);
  } catch (error) {
    console.error('Error fetching stores:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get user's stores
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const [stores] = await pool.query(
      'SELECT * FROM food_stores WHERE owner_id = ?',
      [userId]
    );
    console.log('Fetched user stores:', stores);
    res.json(stores);
  } catch (error) {
    console.error('Error fetching stores:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get pending stores
router.get('/pending', async (req, res) => {
  try {
    const [stores] = await pool.query(
      'SELECT * FROM food_stores WHERE status = "pending"'
    );
    res.json(stores);
  } catch (error) {
    console.error('Error fetching pending stores:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get single store details
router.get('/:id', async (req, res) => {
  try {
    const [stores] = await pool.query(
      'SELECT * FROM food_stores WHERE id = ?',
      [req.params.id]
    );
    
    if (stores.length === 0) {
      return res.status(404).json({ error: 'Store not found' });
    }

    res.json(stores[0]);
  } catch (error) {
    console.error('Error fetching store details:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update store approval status
router.patch('/:id/approval', async (req, res) => {
  try {
    const { status } = req.body;
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }
    
    await pool.query(
      'UPDATE food_stores SET status = ? WHERE id = ?',
      [status, req.params.id]
    );
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

export default router;