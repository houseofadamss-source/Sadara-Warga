import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { searchParams } = new URL(req.url)
  const token = searchParams.get('token')

  // 1. Inisialisasi Supabase
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  let htmlBody = ''
  let statusColor = '#ef4444' // Default Merah (Gagal)

  try {
    // 2. Cari data surat berdasarkan token unik
    const { data: surat, error } = await supabase
      .from('surat_pengantar')
      .select('*')
      .eq('verification_token', token)
      .single()

    if (error || !surat) {
      throw new Error('Dokumen tidak ditemukan atau token tidak valid.')
    }

    statusColor = '#059669' // Hijau Emerald (Sukses)

    // Masking Nama & NIK buat privasi
    const maskName = (name: string) => name.replace(/(..)(.*)(..)/, "$1***$3")
    const maskNik = (nik: string) => nik.substring(0, 6) + "**********"

    htmlBody = `
      <div class="card">
        <div class="icon-box">✅</div>
        <h1 style="color: ${statusColor}">DOKUMEN TERVERIFIKASI ASLI</h1>
        <p class="subtitle">Sistem Informasi Sadara Warga Desa Cihideung Udik</p>
        <hr>
        <div class="info-grid">
          <div class="label">Nomor Surat</div>
          <div class="value">${surat.nomor_surat ?? '-'}</div>

          <div class="label">Nama Pemegang</div>
          <div class="value">${maskName(surat.nama_lengkap || surat.nama_warga)}</div>

          <div class="label">NIK</div>
          <div class="value">${maskNik(surat.nik || surat.nik_warga)}</div>

          <div class="label">Keperluan</div>
          <div class="value"><strong>${surat.keperluan}</strong></div>

          <div class="label">Diterbitkan Pada</div>
          <div class="value">${new Date(surat.approved_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}</div>
        </div>
        <div class="footer">
          Keaslian dokumen ini dijamin oleh database pusat Sadara Warga. <br>
          Generated ID: ${surat.id}
        </div>
      </div>
    `
  } catch (err) {
    htmlBody = `
      <div class="card">
        <div class="icon-box-err">⚠️</div>
        <h1 style="color: ${statusColor}">DOKUMEN TIDAK VALID</h1>
        <p class="subtitle">Mohon hubungi pengurus RT/RW setempat</p>
        <hr>
        <p style="text-align: center; color: #64748b;">${err.message}</p>
      </div>
    `
  }

  // 3. Render Full Page HTML
  const finalHtml = `
    <!DOCTYPE html>
    <html lang="id">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Verifikasi Surat Sadara Warga</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background-color: #f1f5f9; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; padding: 20px; box-sizing: border-box; }
        .card { background: white; padding: 40px; border-radius: 24px; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.1); width: 100%; max-width: 450px; text-align: center; }
        .icon-box { font-size: 60px; margin-bottom: 20px; }
        .icon-box-err { font-size: 60px; margin-bottom: 20px; }
        h1 { font-size: 20px; margin: 0 0 8px 0; font-weight: 900; letter-spacing: -0.5px; }
        .subtitle { font-size: 13px; color: #64748b; margin: 0 0 30px 0; }
        hr { border: 0; border-top: 1px solid #e2e8f0; margin-bottom: 30px; }
        .info-grid { text-align: left; display: grid; grid-template-columns: 1fr; gap: 15px; }
        .label { font-size: 11px; font-weight: 800; color: #94a3b8; text-transform: uppercase; letter-spacing: 1px; }
        .value { font-size: 15px; color: #1e293b; border-bottom: 1px solid #f1f5f9; padding-bottom: 8px; }
        .footer { margin-top: 40px; font-size: 11px; color: #cbd5e1; line-height: 1.6; }
      </style>
    </head>
    <body>${htmlBody}</body>
    </html>
  `

  return new Response(finalHtml, {
    headers: { 'Content-Type': 'text/html; charset=utf-8' },
    status: 200,
  })
})
