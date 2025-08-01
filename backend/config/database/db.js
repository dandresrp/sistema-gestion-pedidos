import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();
const connectionString = process.env.DATABASE_URL;

const { Pool } = pg;
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
});

export const query = (text, params) => pool.query(text, params);
export { pool };
