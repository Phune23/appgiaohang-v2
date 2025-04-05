import express from 'express';
import pool from '../index.js';

const router = express.Router();

// Create new food item
router.post('/', async (req, res) => {
  try {
    const { name, description, price, storeId } = req.body;
    const [result] = await pool.query(
      'INSERT INTO foods (name, description, price, store_id) VALUES (?, ?, ?, ?)',
      [name, description, price, storeId]
    );
    res.status(201).json({ 
      id: result.insertId,
      name,
      description,
      price,
      storeId
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get foods by store ID
router.get('/store/:storeId', async (req, res) => {
  try {
    const [foods] = await pool.query(
      'SELECT * FROM foods WHERE store_id = ?',
      [req.params.storeId]
    );
    res.json(foods);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update food item
router.put('/:id', async (req, res) => {
  try {
    const { name, description, price } = req.body;
    await pool.query(
      'UPDATE foods SET name = ?, description = ?, price = ? WHERE id = ?',
      [name, description, price, req.params.id]
    );
    res.json({ id: req.params.id, name, description, price });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete food item
router.delete('/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM foods WHERE id = ?', [req.params.id]);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get monthly order statistics
router.get('/statistics/:storeId', async (req, res) => {
  try {
    console.log('Fetching statistics for store:', req.params.storeId);

    const [monthlyStats] = await pool.query(
      `SELECT 
        DATE_FORMAT(o.created_at, '%Y-%m') as month,
        COUNT(DISTINCT o.id) as total_orders,
        CAST(SUM(oi.quantity) AS DECIMAL(10,2)) as total_items,
        CAST(SUM(oi.quantity * f.price) AS DECIMAL(10,2)) as total_revenue,
        CAST(AVG(oi.quantity * f.price) AS DECIMAL(10,2)) as average_order_value,
        CAST(SUM(CASE WHEN o.status = 'completed' THEN oi.quantity * f.price ELSE 0 END) AS DECIMAL(10,2)) as completed_revenue,
        COUNT(CASE WHEN o.status = 'completed' THEN 1 END) as completed_orders,
        COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END) as cancelled_orders
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN foods f ON oi.food_id = f.id
      WHERE f.store_id = ?
      AND o.created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
      GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
      ORDER BY month DESC`,
      [req.params.storeId]
    );

    console.log('Monthly stats:', monthlyStats);

    const [overallStats] = await pool.query(
      `SELECT 
        COUNT(DISTINCT CASE WHEN o.status = 'completed' THEN o.id END) as total_completed,
        COUNT(DISTINCT CASE WHEN o.status = 'cancelled' THEN o.id END) as total_cancelled,
        SUM(CASE WHEN o.status = 'completed' THEN oi.quantity * f.price ELSE 0 END) as total_revenue
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN foods f ON oi.food_id = f.id
      WHERE f.store_id = ?`,
      [req.params.storeId]
    );

    console.log('Overall stats:', overallStats[0]);

    const [popularItems] = await pool.query(
      `SELECT 
        f.id,
        f.name,
        SUM(oi.quantity) as total_sold,
        SUM(oi.quantity * f.price) as total_revenue
      FROM orders o
      JOIN order_items oi ON o.id = oi.order_id
      JOIN foods f ON oi.food_id = f.id
      WHERE f.store_id = ?
      GROUP BY f.id, f.name
      ORDER BY total_sold DESC
      LIMIT 5`,
      [req.params.storeId]
    );

    console.log('Popular items:', popularItems);

    res.json({
      monthly_statistics: monthlyStats,
      popular_items: popularItems,
      overall_statistics: overallStats[0]
    });
  } catch (error) {
    console.error('Error fetching statistics:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;