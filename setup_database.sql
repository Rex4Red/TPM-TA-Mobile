/* 
===================================================================
1. BUAT TABEL chapter_updates
   Setiap kali ada chapter baru, sistem akan memasukkan data ke sini.
===================================================================
*/
CREATE TABLE public.chapter_updates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  manga_id TEXT NOT NULL,
  manga_title TEXT NOT NULL,
  cover TEXT,
  old_chapter TEXT,
  new_chapter TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

/* 
===================================================================
2. ENABLE REALTIME
   Supaya aplikasi Flutter bisa mendengarkan perubahan secara langsung 
===================================================================
*/
ALTER PUBLICATION supabase_realtime ADD TABLE chapter_updates;

/* 
===================================================================
3. KONFIGURASI ROW LEVEL SECURITY (RLS)
   Supaya user A tidak bisa melihat notifikasi user B
===================================================================
*/
ALTER TABLE public.chapter_updates ENABLE ROW LEVEL SECURITY;

-- User hanya bisa melihat datanya sendiri
CREATE POLICY "Users can view their own updates" 
ON public.chapter_updates 
FOR SELECT 
USING (auth.uid() = user_id);

-- User bisa update datanya sendiri (misal: is_read jadi true)
CREATE POLICY "Users can update their own updates" 
ON public.chapter_updates 
FOR UPDATE 
USING (auth.uid() = user_id);

-- Edge function (service_role) bisa insert (tidak perlu policy khusus)
