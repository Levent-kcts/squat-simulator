# Prompt - DAILY (gunluk giris odulu, LoginPanel)

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/LoginPanel.luau` (229 satir); `LoginBadge` init.client'ta (dokunma).
**Vurgu rengi**: warn (turuncu)

## Mevcut sorunlar
- 7 gun karti ayni agirlikta; bugun/gecmis/gelecek ayrimi zayif; 7. gun buyuk odulu one cikmiyor.

## Hedef gorunum
Orta pencere: baslik 'DAILY REWARD' + alt satir 'Come back any day - no streak loss' (nazik ton). 7 kart: 1-6 kucuk, 7. gun GENIS ve altin vurgulu (300 Win + Rainbow). Gecmis: tikli, sonuk; bugun hazir: turuncu cerceve + `success` CLAIM nabiz; gelecek: kilit sonuk. Odul ikonlari Win / `potionIcon`.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- `LoginPanel`, `LoginClaim` (CLAIM dugmesi), `LoginDay_*` (her gun icin TAM bir kart; loginpaneltest = #Config.Login.Rewards sayar), `LoginNext`, `LoginReady`, `LoginTotal`. Seri kopmaz kurali, UTC gun mantigi sunucuda; 'seri sifirlanir' DIYE YAZMA.
- Hatirlatma toast'i ve 'Daily' sol menu dugmesi/rozeti init.client'ta.

## Icerik / metin iyilestirmeleri
Odul satiri '+50 Wins', 'Luck 15m'. Hazir degilken 'Next reward tomorrow'.

## Kabul olcutleri
- Bugunun odulu ilk bakista belli; 7. gun cazip ama kisa yazili.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: loginpaneltest, logintest, clienttest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
