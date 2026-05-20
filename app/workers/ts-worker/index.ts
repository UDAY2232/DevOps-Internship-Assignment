import express from 'express';
import fetch from 'node-fetch';

const app = express();
app.use(express.json());

const PORT = process.env.TS_WORKER_PORT ? Number(process.env.TS_WORKER_PORT) : 9002;
const MODEL_HOST = process.env.MODEL_WORKER_HOST || '10.10.0.13';
const MODEL_PORT = process.env.MODEL_WORKER_PORT ? Number(process.env.MODEL_WORKER_PORT) : 9003;

app.post('/rpc', async (req, res) => {
  const { text } = req.body || {};
  if (!text) return res.status(400).json({ error: 'text is required' });

  // Example TS processing: append a tag
  const processed = `${text} [from-ts]`;

  // Forward to model worker
  try {
    const resp = await fetch(`http://${MODEL_HOST}:${MODEL_PORT}/infer`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: processed })
    });
    const body = await resp.json();
    return res.json({ text: processed, model: body });
  } catch (err) {
    return res.status(502).json({ error: String(err) });
  }
});

app.listen(PORT, () => {
  console.log(`TS worker listening on ${PORT}`);
});
