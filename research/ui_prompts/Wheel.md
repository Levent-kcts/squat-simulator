# Prompt - DAILY WHEEL (cark penceresi)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/WheelPanel.luau` (205 satir). Lobideki 3B cark, `WheelController`, `WheelService`, `WheelFace` renklerine DOKUNMA (sahibi renklerle oynanmasini ve tac eklenmesini istemedi).
**Vurgu rengi**: warn (turuncu/sari)

## Mevcut sorunlar
- Karartmali arayuz kalin kontur; SPIN dugmesi ve sonuc metni sade; cark ile cerceve uyumsuz.

## Hedef gorunum
Ortada modal (`fadeScaleIn`): ince cerceveli koyu kart, ustte 'DAILY WHEEL', ortada cark (mevcut `WheelFace`, 8 dilim, ustte ibre), altta buyuk `primary` SPIN (hak yoksa `disabled` + 'Come back tomorrow'), sonuc ciplerle kisa ('+500 Wins'; ekran ortasinda uzun yazi YOK). Kapat sag ustte ghost.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Adlar `WheelGui`, `WheelPanel`, `SpinButton` (ctest tiklar); `HasAutoClick` (Auto Click dilimi pass'liya Rainbow gorunur). Sunucu sonucu secer, istemci verilen dilimde durur; TAM 8 dilim, saat yonu.
- Cark rengi/yuzu degismez, tac YOK.

## Icerik / metin iyilestirmeleri
Sonuc '+250 Wins' / 'Luck Potion 15m' tek satir. Hak: 'Free spin ready!'.

## Kabul olcutleri
- SPIN hazirken net CTA; hazir degilken neden ve ne zaman net.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: wheeltest, ctest, clienttest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
