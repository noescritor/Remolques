import { createClient } from '@supabase/supabase-js';

// Si VITE_API_URL está definida, usamos el proxy HTTPS para evitar mixed-content.
// De lo contrario, conectamos directo a Supabase (modo desarrollo local).
const apiUrl = import.meta.env.VITE_API_URL;
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || '';
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY || '';

const effectiveUrl = apiUrl ? `${apiUrl}/supa-proxy` : supabaseUrl;

export const supabase = createClient(effectiveUrl, supabaseAnonKey);
