import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();
const connectionString = process.env.DATABASE_URL;

const { Pool } = pg;
const pool = new Pool({
  connectionString,
});

export const query = (text, params) => pool.query(text, params);
export { pool };
