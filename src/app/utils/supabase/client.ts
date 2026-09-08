import { createClient } from '@supabase/supabase-js';

// El cliente Supabase apunta al proxy HTTPS de nuestra API para evitar
// el error de mixed-content (HTTPS → HTTP bloqueado por el navegador).
const PROXY_URL = 'https://remolques-remolques-api.gehkp3.easypanel.host/supa-proxy';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

export const supabase = createClient(PROXY_URL, supabaseAnonKey);
