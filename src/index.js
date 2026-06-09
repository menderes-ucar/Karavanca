require('dotenv').config();
const express = require('express');
const cors = require('cors');

const campsRouter = require('./routes/camps');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => res.json({ ok: true }));

app.use('/api/camps', campsRouter);

const PORT = process.env.PORT || 5050;
app.listen(PORT, () => console.log(`API running: http://localhost:${PORT}`));
