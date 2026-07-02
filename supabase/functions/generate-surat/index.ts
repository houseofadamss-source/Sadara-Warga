import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { PDFDocument, StandardFonts } from 'https://cdn.skypack.dev/pdf-lib'
import QRCode from 'https://esm.sh/qrcode'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { record } = await req.json()
    console.log("FUNCTION CALLED FOR ID:", record.id)

    // 1. Inisialisasi Supabase Admin
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // --- RE-FETCH DATA (BIAR DAPET NOMOR SURAT ASLI DARI TRIGGER) ---
    // Kita tunggu sebentar 1 detik biar trigger DB selesai kerja
    await new Promise(resolve => setTimeout(resolve, 1000));

    const { data: finalRecord, error: fetchError } = await supabase
      .from('surat_pengantar')
      .select('*')
      .eq('id', record.id)
      .single()

    if (fetchError || !finalRecord || finalRecord.status !== 'approved') {
      console.log("SKIP: Record not ready or not approved", fetchError)
      return new Response(JSON.stringify({ message: 'Skip: Record not ready or not approved' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      })
    }

    // 2. Bikin PDF Baru (Ukuran A4)
    const pdfDoc = await PDFDocument.create()
    const page = pdfDoc.addPage([595.28, 841.89]) // A4
    const { width, height } = page.getSize()
    const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold)
    const fontRegular = await pdfDoc.embedFont(StandardFonts.Helvetica)

    // --- MULAI NGERENDER LAYOUT ---
    // Kop Surat
    page.drawText('PEMERINTAH KABUPATEN BOGOR', { x: 210, y: height - 50, size: 11, font: fontBold })
    page.drawText('KECAMATAN CIAMPEA', { x: 245, y: height - 65, size: 11, font: fontBold })
    page.drawText('DESA CIHIDEUNG UDIK', { x: 235, y: height - 85, size: 14, font: fontBold })
    page.drawText('RUKUN TETANGGA (RT. 003) RUKUN WARGA (RW.006)', { x: 155, y: height - 105, size: 12, font: fontBold })
    page.drawText('Alamat: Kp. Sinagar RT 003/006 Desa Cihideung Udik Ciampea - Bogor, Bogor', { x: 160, y: height - 120, size: 8, font: fontRegular })

    // Garis Kop
    page.drawLine({ start: { x: 50, y: height - 130 }, end: { x: 545, y: height - 130 }, thickness: 2 })
    page.drawLine({ start: { x: 50, y: height - 134 }, end: { x: 545, y: height - 134 }, thickness: 0.5 })

    // Judul Surat
    page.drawText('SURAT PENGANTAR', { x: 235, y: height - 170, size: 13, font: fontBold })
    page.drawText(`No. : ${finalRecord.nomor_surat ?? '[DIPROSES]'}`, { x: 230, y: height - 185, size: 11, font: fontRegular })

    // Isi Pembuka
    const textOpening = "Yang bertanda tangan dibawah ini Ketua RT 003 RW 006 Desa Cihideung Udik Kecamatan Ciampea Kabupaten Bogor, menerangkan bahwa :"
    page.drawText(textOpening, { x: 50, y: height - 230, size: 10, font: fontRegular, maxWidth: 500 })

    // Data Warga - Pake nama kolom yang konsisten (nik atau nik_warga)
    let yPos = height - 265
    const drawRow = (label: string, value: any) => {
      page.drawText(label, { x: 90, y: yPos, size: 10, font: fontRegular })
      page.drawText(':', { x: 240, y: yPos, size: 10, font: fontRegular })
      page.drawText(String(value ?? '-'), { x: 255, y: yPos, size: 10, font: fontBold })
      yPos -= 18
    }

    drawRow("Nama", finalRecord.nama_lengkap)
    drawRow("Tempat/Tgl Lahir", finalRecord.ttl)
    drawRow("Jenis Kelamin", finalRecord.jenis_kelamin)
    drawRow("No. KTP/KK", finalRecord.nik || finalRecord.nik_warga)
    drawRow("Agama", finalRecord.agama)
    drawRow("Status Perkawinan", finalRecord.status_perkawinan)
    drawRow("Pekerjaan", finalRecord.pekerjaan)
    drawRow("Kewarganegaraan", finalRecord.kewarganegaraan)
    drawRow("Tempat Tinggal", finalRecord.tempat_tinggal)

    // Isi Penutup
    yPos -= 20
    page.drawText('Nama tersebut diatas adalah benar warga RT 003 RW 006 Desa Cihideung Udik Kecamatan Ciampea Kabupaten Bogor, yang bermaksud memohon/mengurus :', { x: 50, y: yPos, size: 10, font: fontRegular, maxWidth: 500 })
    yPos -= 30
    page.drawText(finalRecord.keperluan ?? '-', { x: 100, y: yPos, size: 11, font: fontBold, maxWidth: 400 })
    page.drawLine({ start: { x: 100, y: yPos - 5 }, end: { x: 500, y: yPos - 5 }, thickness: 0.5 })

    yPos -= 40
    page.drawText('Demikian Surat Keterangan ini dibuat sebagai pengantar, dan untuk dipergunakan sebagaimana mestinya.', { x: 50, y: yPos, size: 10, font: fontRegular, maxWidth: 500 })

    // Bagian Tanda Tangan & QR Code
    yPos -= 80
    page.drawText(`Cihideung Udik, ${new Date().toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}`, { x: 400, y: yPos + 15, size: 10, font: fontRegular })

    page.drawText('Ketua RW 006', { x: 70, y: yPos, size: 10, font: fontRegular })
    page.drawText('Ketua RT 003 RW 006', { x: 400, y: yPos, size: 10, font: fontRegular })

    // Generate QR Code
    const qrData = `https://bexwegvrpigxpfpwfjih.supabase.co/functions/v1/verify-surat?token=${finalRecord.verification_token}`
    const qrImageDataUrl = await QRCode.toDataURL(qrData)
    const qrImage = await pdfDoc.embedPng(qrImageDataUrl)
    page.drawImage(qrImage, { x: 260, y: yPos - 60, width: 60, height: 60 })

    page.drawText('Bpk. Sukma Miharja', { x: 70, y: yPos - 70, size: 10, font: fontBold })
    page.drawText('Bpk. Ade Mulyana', { x: 400, y: yPos - 70, size: 10, font: fontBold })

    // 3. Simpan PDF ke Storage
    const pdfBytes = await pdfDoc.save()
    const filePath = `${finalRecord.user_id}/surat_${finalRecord.id}.pdf`

    await supabase.storage.from('arsip_surat').upload(filePath, pdfBytes, {
      contentType: 'application/pdf',
      upsert: true
    })

    const { data: { publicUrl } } = supabase.storage.from('arsip_surat').getPublicUrl(filePath)

    // 4. Update URL di Database (Ini yang bikin warga bisa download)
    await supabase.from('surat_pengantar').update({ file_url: publicUrl }).eq('id', finalRecord.id)

    return new Response(JSON.stringify({ success: true, url: publicUrl }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
