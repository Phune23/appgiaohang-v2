import express from 'express';
import pool from '../index.js';
import admin from 'firebase-admin';

const router = express.Router();

// Add shipping fee calculation helper function
function calculateShippingFee(distance) {
  // Base fee
  const baseFee = 2;
  // Per kilometer fee
  const perKmFee = 0.5;
  return baseFee + (distance * perKmFee);
}

router.post('/', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    
    const { 
      userId, 
      address, 
      latitude, 
      longitude,
      store_address,
      store_latitude,
      store_longitude,
      items, 
      totalAmount, 
      paymentMethod, 
      note,
      shippingFee
    } = req.body;

    // Validate required fields
    if (!userId || !address || !items || !totalAmount || !paymentMethod) {
      throw new Error('Missing required fields');
    }

    // Create order with all coordinates
    const [orderResult] = await connection.query(
      `INSERT INTO orders (
        user_id, address, latitude, longitude,
        store_address, store_latitude, store_longitude,
        total_amount, payment_method, note, shipping_fee
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId, address, latitude || null, longitude || null,
        store_address, store_latitude || null, store_longitude || null,
        totalAmount, paymentMethod, note || null, shippingFee || 0
      ]
    );

    const orderId = orderResult.insertId;

    // Create order items
    for (const item of items) {
      await connection.query(
        'INSERT INTO order_items (order_id, food_id, quantity, price, store_id) VALUES (?, ?, ?, ?, ?)',
        [orderId, item.foodId, item.quantity, item.price, item.storeId]
      );
    }

    await connection.commit();
    res.status(201).json({ 
      message: 'Order created successfully', 
      orderId 
    });

  } catch (error) {
    await connection.rollback();
    res.status(500).json({ error: error.message });
  } finally {
    connection.release();
  }
});

router.get('/user/:userId', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT o.*, 
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'foodId', oi.food_id,
            'quantity', oi.quantity,
            'price', oi.price,
            'storeId', oi.store_id
          )
        ) as items
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.user_id = ?
      GROUP BY o.id
      ORDER BY o.created_at DESC`,
      [req.params.userId]
    );
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get confirmed orders for shippers (Move this before other specific routes)
router.get('/confirmed', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT 
        o.*,
        u.full_name as customer_name,
        u.phone_number as customer_phone,
        o.shipping_fee,
        o.store_latitude,
        o.store_longitude,
        o.latitude,
        o.longitude,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'quantity', oi.quantity,
            'price', oi.price,
            'food_id', f.id,
            'food_name', f.name,
            'store_id', fs.id,
            'store_name', fs.name
          )
        ) as items
      FROM orders o
      INNER JOIN users u ON o.user_id = u.id
      INNER JOIN order_items oi ON o.id = oi.order_id
      INNER JOIN foods f ON oi.food_id = f.id
      INNER JOIN food_stores fs ON oi.store_id = fs.id
      WHERE o.status = 'confirmed'
      GROUP BY o.id
      ORDER BY o.created_at DESC`
    );
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get pending orders - make sure this is properly exposed
router.get('/pending', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT o.*, 
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'foodId', oi.food_id,
            'quantity', oi.quantity,
            'price', oi.price,
            'storeId', oi.store_id
          )
        ) as items
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.status = 'pending'
      GROUP BY o.id
      ORDER BY o.created_at DESC`
    );
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get store orders
router.get('/store/:storeId', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT o.*, 
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'foodId', oi.food_id,
            'quantity', oi.quantity,
            'price', oi.price,
            'storeId', oi.store_id
          )
        ) as items
      FROM orders o
      INNER JOIN order_items oi ON o.id = oi.order_id
      WHERE oi.store_id = ?
      GROUP BY o.id, o.user_id, o.address, o.total_amount, o.status,
               o.payment_method, o.note, o.created_at, o.updated_at
      ORDER BY o.created_at DESC`,
      [req.params.storeId]
    );
    
    res.json(orders || []);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Store reviews order
router.put('/:orderId/review', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const { status } = req.body;
    const orderId = req.params.orderId;

    // Update order status based on store's decision
    const newStatus = status === 'accepted' ? 'confirmed' : 'cancelled';
    
    // Get user's FCM token
    const [userToken] = await connection.query(
      `SELECT u.fcm_token, u.id 
       FROM orders o 
       JOIN users u ON o.user_id = u.id 
       WHERE o.id = ?`,
      [orderId]
    );

    await connection.query(
      'UPDATE orders SET status = ? WHERE id = ?',
      [newStatus, orderId]
    );

    if (status === 'accepted') {
      // Create notification for shippers
      await connection.query(
        'INSERT INTO shipper_notifications (order_id, status) VALUES (?, "pending")',
        [orderId]
      );

      // Send push notification if user has FCM token
      if (userToken[0]?.fcm_token) {
        await admin.messaging().send({
          token: userToken[0].fcm_token,
          notification: {
            title: 'Đơn hàng đã được xác nhận',
            body: `Đơn hàng #${orderId} của bạn đã được cửa hàng xác nhận và đang được chuẩn bị`,
          },
          data: {
            orderId: orderId.toString(),
            type: 'order_confirmed'
          }
        });
      }
    } else {
      // Send cancellation notification
      if (userToken[0]?.fcm_token) {
        await admin.messaging().send({
          token: userToken[0].fcm_token,
          notification: {
            title: 'Đơn hàng đã bị từ chối',
            body: `Đơn hàng #${orderId} của bạn đã bị cửa hàng từ chối`,
          },
          data: {
            orderId: orderId.toString(),
            type: 'order_rejected'
          }
        });
      }
    }

    await connection.commit();
    res.json({ 
      message: 'Order review updated successfully',
      newStatus: newStatus 
    });
  } catch (error) {
    await connection.rollback();
    console.error('Error reviewing order:', error);
    res.status(500).json({ error: error.message });
  } finally {
    connection.release();
  }
});

// Accept order by shipper
router.post('/:orderId/accept', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const { shipperId } = req.body;
    const orderId = req.params.orderId;

    // First check if shipper exists and has correct role
    const [shipperCheck] = await connection.query(
      'SELECT id, role FROM users WHERE id = ?',
      [shipperId]
    );

    if (!shipperCheck.length) {
      throw new Error('Shipper not found');
    }

    if (shipperCheck[0].role !== 'shipper') {
      // If user exists but doesn't have shipper role, update it
      await connection.query(
        'UPDATE users SET role = "shipper" WHERE id = ?',
        [shipperId]
      );
    }

    // Check if order exists and is available
    const [orderCheck] = await connection.query(
      'SELECT id, status FROM orders WHERE id = ?',
      [orderId]
    );

    if (!orderCheck.length) {
      throw new Error('Order not found');
    }

    if (orderCheck[0].status !== 'confirmed') {
      throw new Error(`Order cannot be accepted. Current status: ${orderCheck[0].status}`);
    }

    // Get user's FCM token and shipper info
    const [userInfo] = await connection.query(
      `SELECT u.fcm_token, u.id, sh.full_name as shipper_name 
       FROM orders o 
       JOIN users u ON o.user_id = u.id
       JOIN users sh ON sh.id = ?
       WHERE o.id = ?`,
      [shipperId, orderId]
    );

    // Update order status and assign shipper
    await connection.query(
      `UPDATE orders 
       SET status = "preparing", 
           shipper_id = ?,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = ?`,
      [shipperId, orderId]
    );

    // Send push notification if user has FCM token
    if (userInfo[0]?.fcm_token) {
      await admin.messaging().send({
        token: userInfo[0].fcm_token,
        notification: {
          title: 'Đơn hàng được xác nhận',
          body: `Shipper ${userInfo[0].shipper_name} đã nhận đơn hàng #${orderId} của bạn`,
        },
        data: {
          orderId: orderId.toString(),
          type: 'order_accepted_by_shipper'
        }
      });
    }

    await connection.commit();
    res.json({ 
      success: true,
      message: 'Order accepted successfully',
      orderId: orderId 
    });

  } catch (error) {
    await connection.rollback();
    res.status(400).json({ 
      success: false,
      error: error.message 
    });
  } finally {
    connection.release();
  }
});

// Start delivery route
router.put('/:orderId/start-delivery', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const orderId = req.params.orderId;
    const { shipperId } = req.body;

    // Validate request
    if (!shipperId) {
      throw new Error('Shipper ID is required');
    }

    // Check if order exists and belongs to this shipper
    const [orderCheck] = await connection.query(
      'SELECT id, status, shipper_id FROM orders WHERE id = ?',
      [orderId]
    );

    if (!orderCheck.length) {
      throw new Error('Order not found');
    }

    if (orderCheck[0].shipper_id != shipperId) {
      throw new Error('Unauthorized: Order belongs to different shipper');
    }

    if (orderCheck[0].status !== 'preparing') {
      throw new Error(`Cannot start delivery. Current status: ${orderCheck[0].status}`);
    }

    // Update order status to delivering
    await connection.query(
      'UPDATE orders SET status = "delivering" WHERE id = ? AND shipper_id = ?',
      [orderId, shipperId]
    );

    await connection.commit();
    res.json({ 
      success: true,
      message: 'Delivery started successfully'
    });

  } catch (error) {
    await connection.rollback();
    res.status(400).json({ 
      success: false,
      error: error.message 
    });
  } finally {
    connection.release();
  }
});

// Complete delivery route
router.put('/:orderId/complete-delivery', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const orderId = req.params.orderId;
    const { shipperId } = req.body;

    // Validate request
    if (!shipperId) {
      throw new Error('Shipper ID is required');
    }

    // Check if order exists and belongs to this shipper
    const [orderCheck] = await connection.query(
      'SELECT id, status, shipper_id FROM orders WHERE id = ?',
      [orderId]
    );

    if (!orderCheck.length) {
      throw new Error('Order not found');
    }

    if (orderCheck[0].shipper_id != shipperId) {
      throw new Error('Unauthorized: Order belongs to different shipper');
    }

    if (orderCheck[0].status !== 'delivering') {
      throw new Error(`Cannot complete delivery. Current status: ${orderCheck[0].status}`);
    }

    // Update order status to completed
    await connection.query(
      'UPDATE orders SET status = "completed" WHERE id = ? AND shipper_id = ?',
      [orderId, shipperId]
    );

    await connection.commit();
    res.json({ 
      success: true,
      message: 'Delivery completed successfully'
    });

  } catch (error) {
    await connection.rollback();
    res.status(400).json({ 
      success: false,
      error: error.message 
    });
  } finally {
    connection.release();
  }
});

// Get shipper's active deliveries
router.get('/shipper/:shipperId/active', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT 
        o.*,
        u.full_name as customer_name,
        u.phone_number as customer_phone,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'quantity', oi.quantity,
            'price', oi.price,
            'food_name', f.name,
            'store_name', fs.name,
            'store_address', fs.address,
            'store_phone', fs.phone_number
          )
        ) as items
      FROM orders o
      INNER JOIN users u ON o.user_id = u.id
      INNER JOIN order_items oi ON o.id = oi.order_id
      INNER JOIN foods f ON oi.food_id = f.id
      INNER JOIN food_stores fs ON oi.store_id = fs.id
      WHERE o.shipper_id = ? 
      AND o.status IN ('preparing', 'delivering')
      GROUP BY o.id
      ORDER BY o.created_at DESC`,
      [req.params.shipperId]
    );
    console.log(orders + "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get shipper's completed orders
router.get('/shipper/:shipperId/completed', async (req, res) => {
  try {
    const [orders] = await pool.query(
      `SELECT 
        o.*,
        u.full_name as customer_name,
        u.phone_number as customer_phone,
        JSON_ARRAYAGG(
          JSON_OBJECT(
            'quantity', oi.quantity,
            'price', oi.price,
            'food_name', f.name,
            'store_name', fs.name,
            'store_address', fs.address
          )
        ) as items
      FROM orders o
      INNER JOIN users u ON o.user_id = u.id
      INNER JOIN order_items oi ON o.id = oi.order_id
      INNER JOIN foods f ON oi.food_id = f.id
      INNER JOIN food_stores fs ON oi.store_id = fs.id
      WHERE o.shipper_id = ? 
      AND o.status = 'completed'
      GROUP BY o.id
      ORDER BY o.updated_at DESC`,
      [req.params.shipperId]
    );
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// When order is marked as completed
router.put('/:id/complete', async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    
    const orderId = req.params.id;
    const { shipperId } = req.body;
    
    // Update order status
    await connection.query(
      'UPDATE orders SET status = "completed" WHERE id = ?',
      [orderId]
    );

    // Get order amount and calculate shipper earnings
    const [orderDetails] = await connection.query(
      'SELECT shipping_fee FROM orders WHERE id = ?',
      [orderId]
    );

    const earnings = orderDetails[0].shipping_fee * 0.8; // Changed to 80% of shipping fee

    // Record earnings transaction
    await connection.query(
      'INSERT INTO transactions (user_id, amount, type, description, reference_id) VALUES (?, ?, "order_earning", "Earnings from delivery", ?)',
      [shipperId, earnings, orderId]
    );

    await connection.commit();
    res.json({ message: 'Order completed and earnings recorded' });
  } catch (error) {
    await connection.rollback();
    console.error('Complete order error:', error);
    res.status(500).json({ error: error.message });
  } finally {
    connection.release();
  }
});

export default router;