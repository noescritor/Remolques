import { createClient } from '@supabase/supabase-js';

// URL con .supabase.com (no .co)
const SUPABASE_URL = 'https://djwlchgkeeeqfkreebgq.supabase.com';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqd2xjaGdrZWVlcWZrcmVlYmdxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4MzQ5NTksImV4cCI6MjEwNDQxMDk1OX0.EvPTfH1gi6zI_W3CLWNlpV5X_9jQISC-C8hscVlBsJ4';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
