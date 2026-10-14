# Prompt - GIFTS > PLAYTIME REWARDS

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/GiftsPanel.luau` (383 satir); ortak durum `GiftState.luau` (dokunma).
**Vurgu rengi**: success (yesil)

## Mevcut sorunlar
- 10 odul karti + alt 'Unlock Next' / 'Unlock All' dugmeleri ayni gorsel agirlikta; sayac ve durum (kilitli/hazir/alindi) zayif; bilgi balonu kaba.

## Hedef gorunum
Orta-genis pencere: baslik 'PLAYTIME REWARDS' + altinda 'All claimed = rewards restart'. 5x2 kart izgarasi: ustte sayac ('2:30' ya da kilit), ortada odul ikonu (Win/kas/iksir/`RewardPet` pet resmi), altta durum dugmesi: kilitli `disabled`, hazir `success` 'CLAIM' (nabiz), alindi `secondary` tik. Alt cubuk: genel ilerleme + 'Unlock Next R$ 49' (`secondary`) ve 'Unlock All R$ 149' (`primary`). Bilgi balonu yumusak koyu kart.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Adlar: `RewardIcon`, `RewardPet` (petin KENDI resmi), `RewardTip` (balon: baslangicta gizli, kart dokununca acilir, balona dokunmak kapatir; 1. satir kartlarda altta, 2. satirda ustte), `Info_*`. giftstest balon gorunurlugunu, kart sayisini ve 'CLAIM' TextButton'larini sayar.
- Oznitelikler: `SessionStart`, `GiftCycle`, `ClaimedGifts`, `UnlockedGifts`; tur yalniz 10 odulun HEPSI alinca basa sarar (panelde yazili); 'Unlock' Robux alimi odulu VERMEZ sadece acar; acilacak kilitli odul yoksa satin alma penceresi acilmaz.
- `rewardInfo` metinleri (yeni odul turu eklenirse oraya da).

## Icerik / metin iyilestirmeleri
Sure m:ss; odul adlari kisa ('+500 Wins', 'Luck 15m', pet adi).

## Kabul olcutleri
- Hazir odul 1 saniyede secilir (yesil nabiz); kilitli kartlar sonuk ama okunur.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: giftstest, giftunlocktest, clienttest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
