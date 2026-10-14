# Prompt - BACKPACK > TRAILS & AURAS (CosmeticPanel)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/CosmeticPanel.luau` (292 satir); `makeMenuButton` init.client'ta (dokunma).
**Vurgu rengi**: magic (mor); Trails pembe ton, Auras mor ton

## Mevcut sorunlar
- Kartlar iz/aura temasini yeterince gostermiyor; sahip/takili/alinabilir durumlar renkle degil kalin kontur ile ayriliyor; Win ve Robux fiyat dugmeleri karisik.

## Hedef gorunum
Orta (460) pencere, baslikta secili sekme ('TRAILS'/'AURAS', ayni `options` ile). Kart izgarasi: ustte iz ikonu (`TrailIcon`) ya da aura onizleme dairesi, ad, bonus satiri; alt dugme: Equip (`success`), Equipped (`secondary` + yesil nokta), Buy (`primary` Win fiyati), Robux secenegi kucuk `ghost` 'R$ 40'. Takili kart 2 px success cerceve; Win yetmiyorsa fiyat `textMute`.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- `TrailIcon`: her iz kartinda TAM 1 tane (+ etkinlik izi sahibine ek 1); trailpaneltest sayar. Config.Trails/Auras alanlari (fx, icon, iconTint, emoji, winPrice, robuxPrice), id'ler degismez. Sunucu cagrilari, `PanelManager` kaydi (exclusive=false sekme davranisi), `headerIcon` kurali. Etkinlik (Candy) izi satiri gorunurlugu.

## Icerik / metin iyilestirmeleri
Kart alt metni: ad + etki tek satir. Win ve Robux fiyatlari ayri ama yan yana; sahip olunca fiyat gizlenir.

## Kabul olcutleri
- 3 durum (alinabilir / sahip / takili) renk + etiketle ayirt edilir; telefonda kaydirma akici.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: trailpaneltest, trailfxtest, clienttest, eventdecortest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
