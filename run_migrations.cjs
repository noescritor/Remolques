const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const connectionString = 'postgresql://postgres:4xnaBfG4jirJO1efu@ws2.cloud.betics.com.mx:54322/postgres';

async function runMigrations() {
  const client = new Client({
    connectionString: connectionString,
    ssl: false
  });

  try {
    await client.connect();
    console.log('Connected to DB');

    const migrationsDir = path.join(__dirname, 'supabase', 'migrations');
    const files = fs.readdirSync(migrationsDir).sort(); // They are chronologically prefixed

    for (const file of files) {
      if (file.endsWith('.sql')) {
        console.log(`Running migration: ${file}`);
        const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf-8');
        try {
          await client.query(sql);
          console.log(`Success: ${file}`);
        } catch (err) {
          console.error(`Error in migration ${file}:`, err.message);
          // Don't stop entirely, just log. Some might fail if they already exist without IF NOT EXISTS
        }
      }
    }
  } catch (error) {
    console.error('Connection error', error);
  } finally {
    await client.end();
    console.log('Finished');
  }
}

runMigrations();
