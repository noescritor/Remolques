import { createClient } from '@supabase/supabase-js';

// Usamos el proxy HTTPS de EasyPanel para evitar mixed-content (HTTP→HTTPS bloqueado por navegador)
const SUPABASE_PROXY = 'https://remolques-remolques-supa.gehkp3.easypanel.host';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

export const supabase = createClient(SUPABASE_PROXY, supabaseAnonKey);
