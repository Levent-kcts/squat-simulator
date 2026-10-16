# SENİN YAPACAKLARIN (Creator Hub ve hesap işleri): kısa liste

Tarih: 2026-10-14. Kaynak: `research/` klasöründeki 5 araştırma raporu ve OYUN_BUYUME_PLANI.md.
Ben kodu yazıyorum, GitHub'a gönderiyorum; Roblox hesabın, Creator Hub ve Studio'daki yayın işleri sende. Para harcatan hiçbir adımı onay almadan yapmıyorum, bu listede de para harcatan madde YOK.

## A) BUGÜN, 30 dakika (en önemli iş: 16 oyuncunun asıl sebebi bu olabilir)

Oyun şu an sadece "yaş doğrulamalı 16+" oyunculara açık. Daha geniş kitleye açılması için Roblox bir **değerlendirme** yapıyor ve şunları arıyor. Hangisi eksikse oyun 16+'ın üstüne çıkamaz.

Creator Hub > oyunun üstüne tıkla > **Audience (Hedef kitle) > Reach (Erişim)** sayfası:
1. Sayfanın **ekran görüntüsünü** bana at. "Highly engaged" sayacını (250'de kaçta) ve eksik şart listesini görmem lazım.
2. Eksik şart yazıyorsa hepsini tamamla: **kimlik doğrulama**, **2 adımlı doğrulama (2FA)**, **tam yaş anketi** (sadece ilk soru değil), **1.000 Robux yayın ücreti** ya da Plus aboneliği (sen ücreti daha önce ödedin).
3. Aynı yerde **Advanced Settings**: "Exclude from recommendations" **KAPALI** olsun, "Beta mode" **KAPALI** olsun, gizlilik **Public** olsun.

Ads Manager:
4. **Otomatik kredi yüklemeyi (auto top-up) KAPAT.** Yeni kredi alma. Mevcut kampanyayı 3-5 gün dokunmadan bırak, sonra sonucu birlikte okuruz.

## B) BU HAFTA, para harcamadan (hepsi ücretsiz)

5. **Oynanış videosu yükle.** Oyunun sayfasında Place > Videos. 15-30 saniye, ses ve yazı yok: karakter squat yapıyor, büyüyor, duvarı kırıyor. Roblox kendi testinde videolu oyunlarda oynama süresinin %39'a kadar arttığını söylüyor. Kayıt için oyunda **H tuşu** arayüzü gizler.
6. **3-5 farklı küçük resim** yükle (16:9, birbirinden farklı) ve Thumbnail Personalization'ı aç (Creator Dashboard > Configurations > Places > Thumbnails). Yüklemeden sonra 7 gün dokunma. Hazır görsel promptları `research/05_marketing_visuals.md` bölüm 7'de var, eksik/zayıf olanları değiştirmek için `assets/marketing/` içine de koyacağım.
7. **Share Link üret.** Her kanal için ayrı (TikTok, YouTube, Discord, arkadaşlar). Analytics > Acquisition > Share Links hangi kanalın oyuncu getirdiğini gösterir.
8. **Oyun açıklamasının ilk cümlesini** düzelt: oyunu özetlesin ve anahtar kelime içersin. Örnek: "Squat, grow into a giant, and kick through 100 brick walls in this leg-day simulator with pets, eggs and rebirths." Başlığı sık değiştirme.
9. **Sosyal bağlantı** (varsa Discord/YouTube/TikTok) ekle: sadece yaş doğrulamalı 16+ oyuncular görür, en çok 3 tane.
10. **Experience Event oluştur** (Creator Hub > Engagement > Events & Updates): Halloween etkinliğim hazır olduğunda (24 Ekim) bir etkinlik kaydı aç. Off-Platform Featuring başvurusu için son gün 17 Ekim, ama 16+ oyunların uygun olup olmadığı belli değil, şansı düşük, bedava.

## B1) Halloween etkinliği hazır: yayın ve duyuru (24 Ekim'den ÖNCE yayınla)
**Spooky Gym** kodlandı ve GitHub'a yüklendi (24 Ekim 00:00 UTC - 8 Kasım sonu; kendiliğinden açılır/kapanır, senin bir şey açman gerekmez). **En geç 23 Ekim'de Studio'dan yayınla** (Rojo ile senkronla > File > Publish to Roblox). Yapılacaklar: (1) Experience Event kaydı (yukarıdaki madde 10) etkinlik tarihleriyle; (2) oyun adına yalnızca 24 Ekim-8 Kasım arası tek bir **[🎃]** etiketi ekleyebilirsin (zorunlu değil, 9 Kasım'da kaldır); (3) kısa video: balkabakları, Candy mağazası, 'Pumpkin King' unvanı. Candy sadece oynayarak kazanılır, satılmaz; hiçbir Robux ürünü eklenmedi.

## B2) Kodları duyur (kod sistemi hazır)
Oyunda Settings > Redeem code'dan girilir. Lansman kodları: **LAUNCH, SQUAT, SMASHWALLS, EVOLUTION, LEGDAY, FRIENDS, THANKS**. Oyun sayfası açıklamasına ve videolara yaz ('Codes: LAUNCH, SQUAT ...'); kod listeleme siteleri bunları ücretsiz yayar. Not: oyun içinde link/Discord yazmak yasak, ama açıklama sayfasına kodları yazabilirsin.

## C) Roblox'ta yeni ürün/ayar açman gerekenler (ben yazınca haber vereceğim)
- ~~39 ürünün fiyatını indir~~ **YAPILDI (2026-10-16, Claude Creator Hub'da güncelledi ve doğruladı).**

- **Friend Referral banner'ı:** Creator Hub > Engagement > Referral Rewards > "Add Reward Details" (ad, resim, tarih, davetçi başına limit 3) > Save > Publish. Kodu ben yazıyorum, banner'ı sen açıyorsun.
- ~~İz (trail) ürünlerinin adlarını ve fiyatını güncelle~~ **YAPILDI (2026-10-16).**
- Yeni Robux ürünleri (başlangıç paketi gibi) için ID'ler: kodu hazır yazıp pasif tutacağım, sen ürünü açınca ID'yi bana veririm. Sıra: sen karar verince.

## C2) Rozetleri aç (isteğe bağlı, oyuncu profilinde görünür)
Creator Hub > oyun > **Engagement > Badges > Create**: kod 9 rozeti hazır (`src/shared/Config.luau` > `Badges`; ad ve açıklamalar orada yazılı). Rozet oluşturmak Roblox'ta küçük Robux ücreti isteyebilir; **önce en önemli 3-5 tanesini aç** (welcome, rebirth1, stage10, legendary, mythic). Her rozetin ID'sini bana ver, `Config.Badges.<anahtar>.id` değerine yazarım (id 0 iken o rozet kapalıdır, oyun etkilenmez).

## D) YAPMA listesi (hesabını ve oyunu korur)

- Bot ile ziyaret/oyuncu/beğeni satın alma. Roblox bunu filtreliyor ve hesaba zarar verir.
- "Beğen = ödül" ve "ücretsiz Robux" başlığı/açıklaması. Yanıltıcı küçük resim.
- Oyun içine Discord daveti veya link yazmak.
- Reklam kredisi harcamak (reklamla gelenler Roblox'un öneri sinyallerine sayılmıyor ve "highly engaged" sayacına dönüşümü düşük bildiriliyor).
