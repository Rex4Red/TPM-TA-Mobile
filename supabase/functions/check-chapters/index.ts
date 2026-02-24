import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const shinigamiUrl = 'https://rex4red-shinigami-api.hf.space';

serve(async (req: Request) => {
  // Hanya menerima metode POST
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const supabase = createClient(supabaseUrl, supabaseKey);

  try {
    console.log('🔍 Memulai pengecekan chapter berkala...');

    // 1. Ambil SEMUA bookmark yang sumbernya Shinigami
    const { data: bookmarks, error } = await supabase
      .from('bookmarks')
      .select('*')
      .eq('source', 'shinigami');

    if (error) throw error;
    if (!bookmarks || bookmarks.length === 0) {
      return new Response(JSON.stringify({ message: 'Tidak ada bookmark.' }), {
        headers: { "Content-Type": "application/json" }
      });
    }

    // 2. Ambil daftar manga_id unik agar tidak query API berkali-kali untuk komik yang sama
    const uniqueMangas = [...new Set(bookmarks.map((b: any) => b.manga_id as string))];
    let newChaptersFound = 0;

    // 3. Cek API untuk masing-masing manga
    for (const mangaId of uniqueMangas) {
      if (!mangaId) continue;

      try {
        let cleanId = mangaId.replace('manga-', '');
        let response = await fetch(`${shinigamiUrl}/komik/detail/${cleanId}`);
        let resData = await response.json();

        // Fallback jika ID tanpa 'manga-' gagal
        if (resData.retcode !== 0) {
          response = await fetch(`${shinigamiUrl}/komik/detail/manga-${mangaId}`);
          resData = await response.json();
        }

        if (resData.retcode === 0 && resData.data && resData.data.latest_chapter_number) {
          const latestChapter = `Ch. ${resData.data.latest_chapter_number}`;

          // Ambil semua entri bookmark untuk manga ini
          const mangaBookmarks = bookmarks.filter((b: any) => b.manga_id === mangaId);

          for (const b of mangaBookmarks) {
            const savedChapter = b.last_chapter || '';

            // Jika ada chapter baru dan savedChapter tidak kosong (baru disimpan)
            if (latestChapter !== savedChapter && savedChapter !== '') {
              console.log(`🆕 Chapter baru: ${b.title} → ${latestChapter}`);
              newChaptersFound++;

              // A. Masukkan notifikasi ke tabel chapter_updates
              await supabase.from('chapter_updates').insert({
                user_id: b.user_id,
                manga_id: mangaId,
                manga_title: b.title,
                cover: b.cover,
                old_chapter: savedChapter,
                new_chapter: latestChapter
              });

              // B. Update last_chapter di bookmark
              await supabase
                .from('bookmarks')
                .update({ last_chapter: latestChapter })
                .eq('id', b.id); // Update by raw ID spesifik user
            }
          }
        }
      } catch (errApi: any) {
        console.error(`⚠️ Error fetching manga API: ${mangaId}`, errApi.message || errApi);
      }
    }

    return new Response(JSON.stringify({
      success: true,
      message: 'Pengecekan selesai',
      new_chapters: newChaptersFound
    }), {
      headers: { "Content-Type": "application/json" },
      status: 200
    });

  } catch (error: any) {
    console.error("❌ Fatal Error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500
    });
  }
})
