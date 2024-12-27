require('dotenv').config();
const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());
app.use(express.static('public'));

// Database connection
const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
    const token = req.headers['authorization'];
    if (!token) return res.status(403).json({ error: 'No token provided' });

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
        if (err) return res.status(401).json({ error: 'Unauthorized' });
        req.userId = decoded.id;
        next();
    });
};

// POST API to Create record in table (Registration)
app.post('/api/users', async (req, res) => {
    const { firstName, lastName, mobileNumber, password } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);

    try {
        const [result] = await pool.execute(
            'CALL CreateUser(?, ?, ?, ?)',
            [firstName, lastName, mobileNumber, hashedPassword]
        );
        res.status(201).json({ message: 'User registered successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error registering user' });
    }
});

// GET API to retrieve the record from the table
app.get('/api/users/:id', verifyToken, async (req, res) => {
    try {
        const [rows] = await pool.execute(
            'CALL GetUserById(?)',
            [req.params.id]
        );
        if (rows[0].length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        const user = rows[0][0];
        res.json({
            id: user.id,
            firstName: user.first_name,
            lastName: user.last_name,
            mobileNumber: user.mobile_number
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error fetching user data' });
    }
});

// PUT API to update if needed
app.put('/api/users/:id', verifyToken, async (req, res) => {
    const { firstName, lastName, mobileNumber } = req.body;
    try {
        await pool.execute(
            'CALL UpdateUser(?, ?, ?, ?)',
            [req.params.id, firstName, lastName, mobileNumber]
        );
        res.json({ message: 'User updated successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error updating user' });
    }
});

// DELETE API to delete the record
app.delete('/api/users/:id', verifyToken, async (req, res) => {
    try {
        await pool.execute(
            'CALL DeleteUser(?)',
            [req.params.id]
        );
        res.json({ message: 'User deleted successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error deleting user' });
    }
});

// Login API
app.post('/api/login', async (req, res) => {
    const { mobileNumber, password } = req.body;

    try {
        const [rows] = await pool.execute(
            'CALL GetUserByMobileNumber(?)',
            [mobileNumber]
        );

        if (rows[0].length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const user = rows[0][0];
        const validPassword = await bcrypt.compare(password, user.password);

        if (!validPassword) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        const token = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: '1h' });
        res.json({ token, firstName: user.first_name, lastName: user.last_name });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error logging in' });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

