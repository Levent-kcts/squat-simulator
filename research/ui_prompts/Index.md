# Prompt - PET INDEX

BAGIMSIZ AJAN GOREVI. Proje: `C:\Users\leven\OneDrive\Masaüstü\RobloxOyun` (Roblox/Luau, Rojo). ONCE su dosyalari oku: `CLAUDE.md`, `research/06_ui_modern.md`, `research/ui_prompts/00_shared.md` (ortak kurallar + UIStyle yardimci listesi). `UIStyle.Theme/panel/header/card/button/label/chip/badge/progressBar/tabs/input/press/pop/countTo/fadeScaleIn` tasarim sistemi ajani (prompt 01) tarafindan `src/client/UIStyle.luau`'ya EKLENMIS olmali: dosyayi oku; yardimcilar yoksa DUR ve ana ajana bildir. Gorev: yalniz GORUNUMU modernlestir; mantik, sunucu, oznitelik, Remote ayni kalir. Kod yorumu Turkce, oyun ici metin Ingilizce. UIStyle.luau'ya YAZMA.

**Dosya(lar)**: `src/client/IndexPanel.luau` (212 satir).
**Vurgu rengi**: magic (mor)

## Mevcut sorunlar
- Kesfedilmeyen petler koyu siluet ama kart dili duz; yumurta basliklari ve ilerleme sayaci hiyerarside zayif.

## Hedef gorunum
Genis pencere: baslikta 'PET INDEX' + buyuk ilerleme cubugu ('12/30 - Next reward at 15') + '+12% Leg Muscle' bonus cipi. Yumurta gruplari (`UIListLayout`): grup basligi = yumurta adi + ince ayirici; 5 pet karti yatay; kesfedilmis: renkli (`safePetIcon`) + ad + nadirlik serit; kesfedilmemis: siluet (dim) + '???'. Tamamlanma bonusu karti altin.

## DOKUNULMAYACAKLAR (sozlesmeler, mock testler)
- Oznitelikler `DiscoveredPets`, `IndexBonus`; Config.Index.Rewards metni/'Next reward at N pets'; `petModelIcon`/`safePetIcon` ile `lite=true` (3B ViewportFrame artirma). Sag ust Index dairesi (RightHud) nabzi etkilenmez. ctest Index kurulum kontrolleri.

## Icerik / metin iyilestirmeleri
'Discovered N/30'. Kesfedilmemis ipucu: 'Found in: Forest Egg'.

## Kabul olcutleri
- 30 pet tek bakista: kesfedilen/etmeyen; kaydirma akici.
- `py tools/check.py` 0 sorun, `py tools/mocktest.py` 0 basarisiz. Ilgili testler: ctest, clienttest, raritytest.
- 00_shared.md'deki ortak kabul olcutleri (FredokaOne ve siyah kalin kontur kalmadi, renkler Theme'den, mantik degismedi).
- Raporda: degisen dosyalar, korunan Name/oznitelikler, test sonuclari, UIStyle'a eklenmesini istedigin eksikler, sahibin Studio'da bakacagi 3 sey.
