# YENİ OYUN PROMPT'U: "Tank Ambush: Maze Royale"

> Bu metni yeni bir Claude Code oturumuna OLDUĞU GİBİ yapıştır. Aynı klasördeki `ROBLOX_OYUN_YAPIM_REHBERI.md` de yeni projeye kopyalanacak (adım 0).
> Hazırlanış: 2026-10-22. Sahibin anlatımı ve 6 tur soru-cevaptan çıkarıldı.

---

## ROL VE ÇALIŞMA ŞEKLİ

Sen bu Roblox oyununun tek geliştiricisisin.
- Kodu sen yazarsın (Rojo + Luau).
- Ben (sahibi) Roblox deneyimi olmayan bir IT öğrencisiyim. Studio'da denerim ve yayınlarım.

Dil kuralları:
- Benimle Türkçe konuş.
- Oyun içindeki TÜM yazılar İngilizce olsun.
- Kod yorumları Türkçe olsun.

İşe başlamadan önce:
- `ROBLOX_OYUN_YAPIM_REHBERI.md` dosyasını BAŞTAN SONA oku. §3'teki "her değişiklikten sonra" döngüsünü, §4'teki kayıt güvenliğini ve §5'teki teknik dersleri her zaman uygula.
- Reddedilen ya da onaylanan her kararı `CLAUDE.md`'ye yaz. Durumu ve yapılacakları `README.md`'de tut; README devir dosyasıdır.
- Emin olmadığın oyun tasarımı kararlarında tahmin yapma, kısa bir soruyla sor (seçenekli, önerini işaretle).
- Teknik kararları ve denge sayılarını kendin ver. Hepsini `Config.luau`'ya koy ve bana söyle.

**Yetkilerin:**
1. **Studio'da kendin test et.** Studio MCP ile Play, Output okuma, ekran görüntüsü alma, Lua çalıştırma. Bulduğun sorunu kendin düzelt.
2. **Creator Hub işleri.** Chrome'daki Claude eklentisiyle oyun sayfası, Developer Product, rozet ve görsel yükleme.
3. **Görsel üretimi.** Simge, kapak ve UI simgelerini Gemini'de kendin üret (Chrome'dan).

**Yasaklar:**
- Şifre girme, hesap açma.
- Para ya da Robux harcama.
- Benim sosyal hesaplarımda paylaşım yapma.
- **Yayını (Studio > Dosya > Roblox'ta yayınla) BEN yaparım.** Sen "yayına hazır" dersin ve preflight sonucunu gösterirsin.

---

## ADIM 0: KURULUM (ilk oturum, kendin yap)

1. Proje klasörü: `C:\RobloxProjeler\TankAmbush` (yolda Türkçe karakter OLMASIN).
   - `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun\ROBLOX_OYUN_YAPIM_REHBERI.md` dosyasını oraya kopyala.
   - Bu prompt'u `OYUN_TARIFI.md` olarak kaydet.
2. Rehber §1'deki araçları kontrol et; eksik olanı kur. Önce `where`/sürüm komutuyla neyin zaten kurulu olduğuna bak.
   - Önceki projeden kurulu olanlar: Rokit (rojo 7.7.1, selene, StyLua, lune, wally, luau-lsp), `%USERPROFILE%\.luau\` (luau-analyze, luau.exe), Python (`py`), Git, Blender 5.2, ffmpeg (`C:/Users/leven/tools_dl/...`), OBS, Chrome + Claude eklentisi.
   - Kurulum winget ya da resmi GitHub sürümlerinden yapılır.
   - Kurulum sırasında sorun çıkarsa (yönetici izni, form) bana tek liste ver.
3. Rehber §2'deki iskeleti kur:
   - `default.project.json`, `rokit.toml`, `selene.toml`, `.mcp.json`, `.gitignore`, `src/{loading,shared,server,client}`, `tools/`.
   - Önceki projeden şu araçları UYARLAYARAK kopyala: `check.py`, `mocktest.py` + `mocktest/` (stub'lar), `typecheck.py`, `preflight.py`, `studio_mcp.py`, `tools/icons/cutout.py`.
4. Git deposunu başlat. GitHub'da ÖZEL depo gerekiyorsa adını söyle; ben açarım ya da Chrome'dan birlikte açarız.
5. Studio MCP'nin bağlı olduğunu doğrula (`get_studio_state`). Bağlı değilse bana Türkçe menü adlarıyla tarif et:
   - Studio'da Assistant > … > Ayarlar > MCP Sunucuları > "Enable Studio as MCP server" seçeneğini aç.
   - Sonra Studio'yu ve Claude'u yeniden başlat.
6. Bana boş bir Baseplate açtır, Rojo'yu bağlat. İlk Play'de "merhaba" ekranını MCP ile kendin doğrula.

---

## OYUNUN ÖZETİ

**Tür:** çok oyunculu, kısa turlu, gizlenme ve tahmin üzerine kurulu tank düellosu (battle royale).

**Maç:** 4 tank, küçük bir labirent. Çekirdek döngü:
1. Her tur 10 sn GİZLİ hareketle başlar.
2. Sonra herkes görünür ve aynı anda ateş edilir.
3. Vurulanlar elenir, labirent dıştan küçülür.
4. Son kalan kazanır.

**Kalıcı ilerleme:**
- Puan (rating): kazandıkça artar, kaybettikçe azalır. Eşleşme bu puana göre yapılır.
- Sezonluk rütbe ligi.
- XP ve hesap seviyesi.
- Coin, skinler, kasa.

**Ruh:** "bir maç daha" hissi. Maç 1-2 dakika sürer, telefonda rahat oynanır.

---

## MAÇ KURALLARI (sahibin kararları: değiştirme, belirsizlik varsa sor)

**1. Oyuncu sayısı:** maç başına 4 tank. Sayı Config'te ayarlanabilir; ileride 6'lı mod gelebilir.

**2. Harita:**
- Labirentler ELLE TASARLANMIŞ ve SABİTTİR (rastgele üretim YOK).
- Önce 1 harita: **"Concrete Maze"** (beton labirent, çizgi film oyuncak tarzına uygun, yumuşak renkli beton).
- Yayından önce 3-4 haritaya çıkacak; temalarını o zaman soracağım.
- Haritalar veri olarak tanımlanır (ör. ızgara dizisi) ve kodla kurulur, ki yenisi kolay eklensin.
- Her haritanın 4 doğma noktası birbirinden uzak ve adil olmalı.

**3. Tur akışı:**
- **a) Gizli faz (10 sn, Config):**
  - Herkes serbestçe hareket eder. Kimse kimseyi GÖREMEZ: rakip tanklar her oyuncunun ekranında tamamen gizlenir.
  - Sunucu kimsenin konumunu diğer istemcilere göstermez: gizli fazda rakip konumu istemciye GÖNDERİLMEZ ya da tanklar her istemcide yerel olarak gizlenir. Hile yapılamaması için ilki tercih edilir: sunucu yetkili hareket ya da gizli fazda rakip tankın çoğaltılmaması.
  - Ekranda büyük geri sayım görünür.
- **b) Ateş:**
  - Gizli fazda oyuncu istediği an ATEŞ tuşuna basabilir. Basınca tankı o anda DURUR ve kilitlenir; nişanı tankın ön yönüdür.
  - Mermi o an UÇMAZ. Tüm mermiler süre sonunda aynı anda atılır.
  - 10 sn içinde ateş etmeyen tank, süre bitince baktığı yöne OTOMATİK ateş eder.
  - Her turda tank başına 1 mermi.
- **c) Görünme ve hesaplaşma (3 sn, Config):**
  - Süre bitince herkes görünür, tanklar donar ve tüm mermiler aynı anda atılır.
  - Mermiler DÜZ gider, ilk duvarda yok olur, ilk değdiği tankı vurur ve orada durur.
  - Vurulan tank patlar (skinin patlama efekti) ve elenir.
  - Aynı anda vurulanlar aynı sırayı paylaşır.
  - Mermi uçuşu kısa ve görünür olsun; sinematik bir "hesaplaşma" anı.
- **d) Küçülme:**
  - Turdan sonra labirentin DIŞ HALKASI kapanır (duvar yükselir ya da kapanır).
  - Dışarıda kalan tank güvenli en yakın iç hücreye itilir.
  - Sonra yeni gizli faz başlar.
- **e) Ani ölüm:**
  - Harita en küçük hâline gelince turlar kısalır (ör. 5 sn).
  - Herkes aynı anda ölürse son kalanlar berabere sayılır.
  - Son kalan tank kazanır.

**4. Kamera ve kontrol:**
- ÜÇÜNCÜ ŞAHIS kamera, tankın arkasından.
- Nişan YOK: mermi tankın ön yönüne gider; nişan almak için tank döndürülür.
- PC: W/S ileri-geri, A/D dönüş, Boşluk ateş.
- Telefon: sol joystick + büyük ATEŞ düğmesi.
- Telefon ve bilgisayar İLK GÜNDEN desteklenir (rehber §5.16 dokunuş dersleri). Konsol şimdilik yok.

**5. Oyundan çıkan:**
- Maç ortasında çıkan oyuncu kaybetmiş sayılır ve puan kaybeder.
- Yerine bot girmez; tankı yok olur.
- AFK kalan oyuncu zaten otomatik ateşle oynamış olur.

---

## MENÜ, EŞLEŞME, BOTLAR

**1. Giriş ekranı:**
- Oyun açılınca ana menü çıkar: PLAY, Shop, Crates, Profile, Rank.
- Arkada oyuncunun tankı 3B bir garajda yavaşça döner; skinler burada denenir.
- Arayüz önceki oyunun beğenilen tarzında: kalın siyah kenar, FredokaOne yazı, yumuşak gradyan (rehber, eski tema).

**2. Maç arama (PLAY):**
- "Searching..." ekranı, bekleme süresi ve İptal düğmesi.
- Oyuncular puanlarına göre eşleşir; bekledikçe puan aralığı genişler.
- Teknik öneri: lobi ve maç ayrı place olsun. Kuyruk MemoryStoreService ile tutulur, maç TeleportService:ReserveServer ile ayrı sunucuda oynanır. Az oyuncuda tek sunucu içi eşleşme yedeği olsun. Mimariyi kendin seç, nedenini README'ye yaz.
- Arkadaşla parti ve özel maç ŞİMDİLİK YOK.

**3. Botlar:**
- Aramadan **15 sn** sonra (Config) eksik yerler botla dolar.
- **5 zorluk seviyesi.** Oyuncunun son 10 maçtaki kazanma oranı %50'yi geçtikçe bot seviyesi yükselir, düştükçe iner; yeni oyuncu en kolaydan başlar.
- Seviyeler şunları değiştirir: tepki/karar süresi, rota seçimi (labirentte saklanma), son görünme anındaki konumlardan tahmin isabeti, ateş zamanlaması.
- Botlar sunucuda çalışır.
- **İsimler:** botlar GERÇEK OYUNCU GİBİ görünür (sahibin kararı).
  - İsimler uydurma, oyuncu adına benzeyen isimlerdir (ör. "TankMaster_482"). ASLA gerçek bir Roblox kullanıcı adı kopyalanmaz.
  - Avatar ve skinleri rastgele seçilir.
  - Botlar sıralama panosuna ve sezon listesine GİRMEZ.
- **Puan:** botlu maçlar puanı TAM etkiler (sahibin kararı).

---

## PUAN, RÜTBE, SEZON

- **Puan:** gizli olmayan rating, başlangıç 1000.
  - 4 kişilik maçta sıraya göre değişir: 1. çok artar, 2. biraz artar, 3. biraz azalır, 4. çok azalır. Rakiplerin puanı hesaba katılır (Elo'nun çok oyunculu hâli).
  - Berabere kalanlar sırayı paylaşır.
  - Formül ve katsayılar Config'te.
- **Rütbeler:** Bronze, Silver, Gold, Platinum, Diamond, Master.
  - Her biri renkli rozetli; alt kademeleri (I-III) kendin öner.
  - Rozet menüde, maç sonu ekranında ve tankın üstündeki isim etiketinde görünür.
- **Sezon:**
  - Her ay biter. Puan kısmen sıfırlanır (ör. 1000'e doğru yarı yarıya).
  - Sezon sonunda ulaşılan en yüksek rütbeye göre o sezona özel skin ödülü verilir.
  - Sezon sayacı menüde görünür.
- **Sıralama panosu:** sezonluk ve tüm zamanlar, menüde (OrderedDataStore). Botlar hariç.

---

## İLERLEME VE EKONOMİ

**1. Maç sonu ekranı:**
- Sıran, puan değişimi (+/-), kazanılan XP ve Coin.
- Seviye çubuğu, "PLAY AGAIN" düğmesi.

**2. XP ve seviye:**
- Her maç XP verir; kaybedene de verir, daha az.
- Seviye atlayınca Coin ödülü gelir; bazı seviyelerde ücretsiz skin.

**3. Coin:**
- Maç sonunda sıraya göre verilir.
- Robux ile SATILMAZ (sahibin kararı). Böylece kasa "paralı rastgele ürün" sayılmaz ve her ülkede açık kalır.

**4. Dengeleme:**
- Önceki projenin `simulate.py` yaklaşımıyla bir ekonomi simülasyonu yaz.
- Hedefler (önerim, Config'te ayarlanabilir):
  - ilk kasa ~3-5 maçta açılır;
  - bir Epic ~1 saatte gelir;
  - bütün Common/Rare skinler ~10 saatte toplanır.

**5. Önceki oyunun retention kalıpları:**
- Günlük görevler, giriş ödülü, kodlar şimdilik İSTENMEDİ, ekleme.
- Sadece XP seviyesi, Coin, kasa, sezon ve rütbe var. Sonra sorarım.

---

## SHOP VE KASALAR (sadece kozmetik; skinler HİÇBİR güç vermez)

**1. Skin türleri:**
- **Tank boyası/modeli:** renk, desen ve birkaç farklı tank gövdesi.
- **Mermi izi:** renkli iz ve parlama.
- **Patlama efekti:** vurulan tankın patlaması; konfeti, şimşek gibi.

**2. Nadirlik:**

| Nadirlik | Renk | Kasa şansı |
|---|---|---|
| Common | gri | %60 |
| Rare | mavi | %25 |
| Epic | mor | %10 |
| Legendary | altın | %4 |
| Mythic | kırmızı | %1 |

**3. Kasa (Coin ile açılır):**
- Açılış animasyonu CS:GO tarzı: ortada sabit bir dikey çubuk durur, skin kartları sağdan sola kayarak yavaşlar ve çubuğun altındaki kartta durur.
- Kart kenarı nadirlik renginde. Mythic ve Legendary için ekstra parıltı ve ses.
- Kasa paneli içerikleri ve YÜZDELERİ açılıştan önce gösterir.
- Sonucu SUNUCU seçer; animasyon sunucunun sonucunda durur.
- Sahip olunan skin tekrar çıkarsa nadirliğine göre Coin'e döner.

**4. Doğrudan satın alma:**
- Shop'ta istenen skin doğrudan alınabilir: Robux ile (Developer Product, fiyat aralığı ~25-99 R$, önerini ver) ya da Coin ile.
- En nadir ve sezon skinleri doğrudan Coin ile satılmayabilir; öner.
- Ürün ID'leri 0 iken düğmeler "coming soon" der.

**5. Çocuk güvenliği:**
- Kasa Robux ile açılmaz ve Coin satılmaz. Yine de PolicyService kontrolü ve yüzde gösterimi kodda bulunsun (rehber §6).

**6. Robux ürünleri sadece skin.** Game pass, iksir ve güç yok (sahibin kararı: "shop'ta sadece skin satılır").

---

## GÖRSEL, SES, MODELLER

**1. Tarz:**
- Çizgi film OYUNCAK TANKLAR: tombul, parlak renkli, büyük palet ve namlu, sevimli.
- Beton labirent yumuşak tonlu, okunaklı; duvarlar tankı tamamen saklayacak yükseklikte.
- Aydınlık sahne. Karanlık ve mavi hava sahibine hoş gelmiyor (önceki oyundan).

**2. 3B modeller Blender'da senin işin** (rehber §7):
- Birkaç tank gövdesi + boyanabilir parçalar.
- Boyanacak parçalar DOKUSUZ olmalı (Color dokuyla çarpılmaz).
- Önizleme render'ını bana göster, onaydan sonra Studio'ya kendin aktar.
- Model yoksa kodla çizilen basit tank yedeği kalsın.

**3. Simgeler ve kapak:** Gemini ile, "game icon set" üslubunda (rehber §7).

**4. Sesler:**
- Motor uğultusu (kısık), ateş, patlama, geri sayım tik'leri, "hesaplaşma" vuruşu, kasa kayma tıkırtısı, nadir kart sesi.
- Creator Store'dan seç ya da Blender Python ile üret.
- Sürekli çalan sesler kısık olsun.

**5. Müzik:** menüde neşeli, maçta gergin ve kısa döngü; ses ayarı olsun.

---

## TEKNİK ŞARTLAR

- Sunucu her şeye karar verir: hareket doğrulaması, ateş, isabet, eleme, puan, Coin, kasa sonucu, satın alma. İstemciye güvenme.
- Gizli fazda rakip konum bilgisi istemciye sızmamalı: hile yapan istemci rakibi görmesin.
- Hız ve ışınlanma hilesine karşı sunucu kontrolü olsun.
- **Kayıt:** rehber §4'ün TAMAMI uygulanır.
  - Kaydedilenler: puan, rütbe, sezon, XP, Coin, skinler, takılı skinler, istatistikler (maç, galibiyet, vuruş), ayarlar.
  - Oturum kilidi, kayıt denemeleri, "önce kaydet sonra ödül ver".
  - `StoreName` yayından sonra değişmez.
  - Studio çekim modu (StudioReadOnly).
- Ayarlar penceresi: müzik, efekt sesi, kamera hassasiyeti, (telefonda) düğme boyutu.
- **Performans:** telefonda 60 fps hedefle.
  - Az parçacık, uzak efektleri kapat.
  - Her karede ağır döngü yazma.
  - Harita parça sayısını düşük tut.
- **Analitik:** maç başladı, bitti, sıra, süre; ilk maç hunisi; kasa açılışı; satın alma. AnalyticsService kullan.
- **Testler:**
  - mocktest ile tur akışı, isabet hesabı, puan formülü, kasa olasılıkları (çok sayıda çekilişle %60/25/10/4/1 doğrulaması), kayıt.
  - Bot karar mantığı ve eşleşme için de test yaz.
  - MCP ile gerçek Play testi: 1 oyuncu + 3 bot maçı baştan sona oynat, Output'ta hata olmadığını ve ekran görüntüsünde arayüzün doğru durduğunu kendin doğrula.

---

## YAPIM SIRASI (her adım sonunda bana kısa rapor ve "Studio'da şuna bak")

1. Kurulum (adım 0) ve iskelet.
2. **Çekirdek maç, botsuz, tek sunucuda:**
   - basit kod tankları, Concrete Maze, hareket;
   - gizli faz, ateş kilidi, hesaplaşma, eleme, dış halka küçülmesi, ani ölüm, kazanan.
3. **Botlar:** 5 seviye ve kazanma oranına göre zorluk.
4. **Menü ve garaj:** PLAY, arama, 15 sn sonra bot doldurma, maç sonu ekranı.
5. **Kayıt, ilerleme ve sıralama:** puan, rütbe, sezon, XP, Coin, sıralama panosu.
6. **Shop ve kasalar:** CS:GO tarzı açılış, skin türleri (önce kodla basit görünümler).
7. **Gerçek eşleşme:** lobi ve maç sunucuları, MemoryStore kuyruğu, telefon kontrolleri.
8. **Görseller ve ses:** Blender tankları, efektler, sesler, müzik, simgeler.
9. **Haritalar:** 3-4'e çıkar (temalarını sor), denge simülasyonu, performans.
10. **Yayın hazırlığı:**
    - Robux skin ürünlerini Creator Hub'da oluştur, ID'leri bağla.
    - preflight, yaş anketi taslağı, oyun sayfası metni.
    - Kapak ve küçük resimler (Gemini + oyun içi H modu), 15-30 sn video (rehber §8 tarifi).
    - Bana "yayına hazır" raporu ver.

Her adımın sonunda:
- check, mocktest ve typecheck çalıştır;
- MCP ile Play testini yap;
- README ve CLAUDE.md'yi güncelle;
- commit at ve push et.

---

## ŞİMDİLİK İSTENMEYENLER (sorulmadan ekleme)

- Arkadaşla parti ve özel maç.
- Günlük görev, giriş ödülü, promosyon kodu.
- Game pass, iksir ve güç veren her şey.
- Coin satışı.
- Mermi sekmesi, lazer, taret ile serbest nişan.
- Rastgele üretilen labirent.
- Konsol desteği.

---

## BAŞLARKEN

İlk mesajında:
1. Rehberi okuduğunu ve özetini 5 maddede söyle.
2. Kurulum durumunu göster: kurulu olanlar ve eksikler.
3. Bu tarifte hâlâ belirsiz bulduğun noktaları seçenekli sorularla sor.

Sonra adım 0'a başla.
