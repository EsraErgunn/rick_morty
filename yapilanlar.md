# Yapılanlar – Portal Cards

Bu belge, projede bugüne kadar yapılan her şeyi, projenin amacını ve dosya düzenini (sırayla, hangi dosyanın ne işe yaradığı) özetler.

Tanıtım sunumu: [`docs/sunum/index.html`](docs/sunum/index.html) (tarayıcıda aç, ← / → ile ilerle).

---

## 1. Projenin amacı

**Portal Cards**, herkese açık [Rick and Morty API](https://rickandmortyapi.com/) verisiyle çalışan bir **koleksiyon kartı + sıra tabanlı savaş oyunudur**. Flutter ile Android ve iOS için yazıldı. Bir bitirme projesidir; öğretmenin zorunlu şartı **animasyon ve ses efektleri**dir.

**Oyun döngüsü:** portal aç → kart kazan → deste kur → savaş → coin kazan → yeniden portal aç.

Ne işe yarar / neyi gösterir:

- **Gerçek veriden oyun üretmek:** API'deki 800'den fazla karakter, kendi sabit istatistiklerine sahip bir karta dönüşür. Nadirlik bölüm sayısından, tür (İnsan / Robot / Uzaylı …) `species` alanından, pasif yetenek `status` alanından gelir. Aynı karakter her zaman aynı kartı verir.
- **Çevrimdışı çalışma:** ilk açılışta tüm veri telefona indirilir (Hive); sonra internet gerekmez.
- **Animasyon ve ses:** fragment shader ile portal ve holografik kart efekti, kart çevirme, 3B eğilme, savaş animasyonları (saldırı, sarsılma, hasar sayıları, HP çubuğu, bayılma), 15 ses efekti + 3 müzik (hepsi kodla üretildi) ve titreşim geri bildirimi.
- **Temiz mimari:** oyun kuralları saf Dart'ta, tamamen test edilmiş; ekranlar Bloc ile yönetiliyor.

> Hayran projesi, ticari değil. Rick and Morty, karakterleri ve görselleri Adult Swim / Warner Bros. Discovery'ye aittir. Uygulama mağazaya konmayacak.

---

## 2. Bugüne kadar yapılanlar (özet)

| Aşama | Yapılanlar |
|---|---|
| **Hazırlık** | Vizyon ve kapsam (`docs/PROJECT.md`), MVP şartnamesi (`docs/SPEC.md`), oyun kuralları skill'i, güvenlik profili (L1), uygulama planı (`tasks/plan.md`). |
| **1. hafta – Temel** | Proje iskeleti, tema token'ları (renk, yazı, boşluk, hareket), Hive depolama, Dio istemcisi (zaman aşımı + yeniden deneme), API senkronizasyonu ve açılış ekranı, saf Dart oyun motoru (nadirlik, tür, istatistik, pasif, ekonomi, portal çekilişi), ses servisi, titreşim servisi, sensörler (sallama, eğilme). |
| **2. hafta – Kartlar ve portal** | `GameCard` bileşeni (nadirlik çerçevesi, holo shader, çevirme, 3B eğilme), portal ekranı (sallayarak açma, shader portal, kart açılış sahnesi, efsanevi sinematik), koleksiyon ekranı (filtre, sıralama, kart detayı), ana menü, ayarlar (ses/müzik/titreşim, görsel indirme, gizli demo modu), prosedürel ses üretimi (`tools/audio`). |
| **3. hafta – Deste ve savaş** | Deste kurucu (3 slot, toplamlar, tür kapsaması), savaş motoru ve yapay zekâ, rakip üretimi (5 zorluk kademesi), savaş ekranı (ön-savaş, olay tekrar oynatma, 2× hız, sonuç ve ödül), özel karakterler (Rick, Morty, Summer, Pickle Rick, Mr. Meeseeks) ve yetenekleri, denge simülasyonu (`docs/balance.md`). |
| **Teslim öncesi düzeltmeler** | Açılış → menü geçişinde donma düzeltildi (zamanlayıcı yedeği), shader'lar süre sınırıyla önceden yükleniyor (`DISABLE_SHADERS` teşhis bayrağı), Android 12+ koyu açılış ekranı, HP çubuğu görünmeme hatası, her ekrana görünür geri butonu + Android geri tuşu, görsel inmezse baş harf + nadirlik rengi gösteren yer tutucu, release APK için eksik INTERNET izni, README. |

Durum: **80+ commit**, **457 test** geçiyor, `flutter analyze --fatal-infos` temiz. Release APK'lar (arm64-v8a, armeabi-v7a, x86_64) üretildi.

Kalanlar: episode albümü ekranı (şimdilik yer tutucu), boyut haritası ve birleştirme (ek hedefler), Mr. Meeseeks duman efekti. Emülatörde karakter görsellerinin inmesi Avast HTTPS taraması yüzünden henüz doğrulanamadı.

---

## 3. Dosya düzeni (sırayla)

### 3.1 Kök dizin

| Dosya | Ne işe yarar |
|---|---|
| `CLAUDE.md` | Proje kuralları: teknoloji yığını, mimari, kod kuralları, komutlar, git kuralları. |
| `README.md` | Projenin İngilizce tanıtımı, özellikler, çalıştırma ve derleme adımları, hayran projesi notu. |
| `yapilanlar.md` | Bu belge. |
| `pubspec.yaml` / `pubspec.lock` | Paketler, font/ses/görsel asset'leri ve shader listesi; kilitli paket sürümleri. |
| `analysis_options.yaml` | Lint kuralları (`flutter analyze`). |
| `dart_test.yaml` | Test ayarları (golden testleri yalnızca Windows'ta çalışır). |
| `l10n.yaml` | Türkçe metinlerin kod üretimi ayarı. |
| `.gitignore`, `.gitattributes`, `.metadata` | Git ve Flutter ayar dosyaları. |

### 3.2 `.claude/` – Claude Code kuralları

| Dosya | Ne işe yarar |
|---|---|
| `rules/architecture.md` | Katman kuralları, oyun motorunun saf olması, Bloc ve Hive kuralları. |
| `rules/animation-audio.md` | Animasyon süreleri/eğrileri ve ses kuralları. |
| `rules/testing.md` | Neyin nasıl test edileceği. |
| `skills/rm-game-mechanics/SKILL.md` | Oyun kurallarının tek kaynağı: nadirlik, tür, istatistik formülü, savaş, ekonomi. |
| `settings.json` | Claude Code izin ayarları. |

### 3.3 `docs/` – Belgeler

| Dosya | Ne işe yarar |
|---|---|
| `PROJECT.md` | Vizyon, kapsam, yol haritası. |
| `SPEC.md` | MVP şartnamesi: her ekranın kabul kriterleri, animasyon ve tasarım kuralları. |
| `balance.md` | Savaş dengesi simülasyonu ve kararlar. |
| `SECURITY_GUIDELINES.md`, `security-profile.md` | Güvenlik kuralları ve projenin L1 profili. |
| `design/palette_preview.html` | Renk paletinin önizlemesi. |
| `perf/README.md` | Performans ölçüm notları (`START_ROUTE` ile doğrudan ekran açma). |
| `sunum/index.html` | Tanıtım sunumu (görselli, tek dosya). |

### 3.4 `tasks/plan.md`

Haftalara bölünmüş uygulama planı (T1 … T48) ve her haftanın durumu.

### 3.5 `assets/` – Uygulama içi dosyalar

| Klasör / dosya | Ne işe yarar |
|---|---|
| `audio/sfx/*.wav` | 15 ses efekti: buton, kart çevirme, coin, vuruş, kritik, süper etkili, bayılma, zafer, yenilgi, portal şarjı/açılışı, nadir/efsanevi açılış, dahi kritiği, Meeseeks "poof". |
| `audio/music/*.wav` | Menü müziği, savaş müziği, efsanevi açılış müziği. |
| `audio/CREDITS.md` | Seslerin kaynağı (hepsi `tools/audio` ile üretildi). |
| `fonts/grandstander/` | Başlık fontu (çizgi film hissi) + lisansı. |
| `fonts/atkinson_hyperlegible_next/` | Okunaklı gövde fontu + lisansı. |
| `images/menu_bg.webp`, `splash_bg.webp` | Menü ve açılış ekranı arka planları. |

### 3.6 `shaders/` – GPU efektleri

| Dosya | Ne işe yarar |
|---|---|
| `portal.frag` | Dönen yeşil (efsanevide kırmızı) portal efekti. |
| `holo.frag` | Kartların üzerindeki holografik folyo; nadirlik arttıkça güçlenir. |

### 3.7 `lib/main.dart`

Uygulamanın giriş noktası: Hive'ı açar, bağımlılıkları kurar (DI) ve uygulamayı başlatır.

### 3.8 `lib/app/` – Uygulama kabuğu

| Dosya | Ne işe yarar |
|---|---|
| `app.dart` | Kök widget: yalnız Türkçe, yalnız koyu tema. |
| `app_info.dart` | Arayüzde gösterilen sürüm bilgisi. |
| `di.dart` | get_it servis bulucusu: tüm servisler, depolar ve ekranlar burada bağlanır. |
| `router.dart` | go_router rotaları; tüm ekranlar menünün altında, böylece geri tuşu doğru üst ekrana döner. |
| `start_route.dart` | Performans ölçümü için uygulamayı doğrudan bir ekranda açma (`--dart-define=START_ROUTE`). |
| `not_found_page.dart` | Bilinmeyen adres ekranı. |
| `placeholder_page.dart` | Henüz yapılmamış ekranlar için geçici sayfa (albüm). |
| `debug/card_lab_page.dart` | Sadece debug derlemede: kartları tüm nadirliklerde deneme ekranı. |
| `theme/colors.dart` | Renk token'ları ("boşlukta çizgi film mürekkebi"). |
| `theme/typography.dart` | Yazı stilleri ve fontlar. |
| `theme/spacing.dart` | 4 dp ızgarasında boşluk, köşe, çizgi kalınlığı ve boyut token'ları. |
| `theme/motion.dart` | Animasyon süreleri ve eğrileri. |
| `theme/card_style.dart` | Nadirliğe göre kart çerçevesi renk ve stilleri. |
| `theme/app_theme.dart` | Token'lardan kurulan tek Material teması. |

### 3.9 `lib/core/` – Ortak çekirdek

**Oyun motoru (`core/game/`, saf Dart, Flutter'sız):**

| Dosya | Ne işe yarar |
|---|---|
| `rarity.dart` | Bölüm sayısından nadirlik (Sıradan / Nadir / Epik / Efsanevi). |
| `card_type.dart` | `species` alanından tür ve tür üçgeni (İnsan → Robot → Uzaylı → İnsan). |
| `card_stats.dart` | Karakter id'sinden sabit HP / ATK / DEF / SPD. |
| `passives.dart` | `status` alanından pasif: Zombi (bir kez dirilir), Belirsiz (hasar ±%20). |
| `featured.dart` | Özel karakterler ve imza yetenekleri (Rick "DAHİ!", Meeseeks "Görev tamam!"). |
| `battle_model.dart` | Savaştaki kartın canlı durumu ve savaş olayları. |
| `battle_engine.dart` | Bir turu hesaplar, olay listesi döndürür; arayüzü beklemez. |
| `battle_ai.dart` | Basit, okunabilir yapay zekâ (tür avantajı, en düşük can). |
| `opponents.dart` | Zorluk kademesine göre rakip takımı. |
| `portal_roll.dart` | Portal çekilişi (%60 / %28 / %10 / %2), ilk 3 portalda tekrar yok. |
| `economy.dart` | Coin kuralları; bakiye yalnız buradan değişir, 0'ın altına düşmez. |

**Diğer çekirdek klasörler:**

| Dosya | Ne işe yarar |
|---|---|
| `cards/card_factory.dart` | Karakterden kart verisi üretir (yalnız oyun motoru formülleriyle). |
| `cards/game_card_data.dart` | Bir kartın gösterdiği her şey. |
| `cards/rarity_pool.dart` | Portal çekilişi için nadirliğe göre gruplanmış karakterler. |
| `entities/character.dart`, `episode.dart`, `location.dart` | API'den gelen varlıkların oyun içi modelleri. |
| `errors/failures.dart` | Depoların döndürdüğü hata türleri (`Either<Failure, T>`). |
| `audio/audio_assets.dart` | Ses dosyalarının listesi. |
| `audio/audio_backend.dart` | audioplayers sarmalayıcısı (testte sahtesi kullanılır). |
| `audio/audio_service.dart` | Tüm sesler buradan çalar; ayarlara uyar. |
| `haptics/haptics_service.dart` | Tüm titreşimler buradan; ayara uyar. |
| `feedback/ui_feedback.dart` | Sıradan arayüz anları için ortak ses + titreşim. |
| `sensors/shake_detector.dart` | Telefon sallamayı algılar (portal açmak için). |
| `sensors/tilt_stream.dart` | İvmeölçerden kart eğilmesi. |
| `images/image_download_controller.dart` | Uygulama çapında görsel indirme (önce sahip olunan kartlar). |
| `images/image_precacher.dart` | Tek bir görseli disk önbelleğine koyar. |
| `logging/app_logger.dart` | Sadece debug'da log (`print` yok). |
| `network/endpoints.dart` | API adresleri (yalnız HTTPS). |
| `network/dio_client.dart` | Dio sarmalayıcısı; asla exception fırlatmaz. |
| `network/retry_interceptor.dart` | 429/5xx hatalarında artan bekleme ile en fazla 3 yeniden deneme. |
| `storage/hive_init.dart` | Hive kutularını açar. |
| `storage/hive_type_ids.dart` | Tüm Hive tip id'leri tek yerde. |
| `storage/api_data_store.dart` | Karakter / bölüm / konum kutuları. |
| `storage/player_store.dart`, `player_state.dart` | Oyuncu verisi: coin, deste, ayarlar, ilerleme. |
| `storage/stored_models.dart` (+ `.g.dart`) | Hive'a yazılan modeller ve üretilmiş adaptörleri. |
| `widgets/game_card/game_card.dart` | 5:7 oranlı kart bileşeni. |
| `widgets/game_card/card_front.dart`, `card_back.dart` | Kartın ön ve arka yüzü. |
| `widgets/game_card/card_art.dart` | Karakter görseli (`CachedNetworkImage`); inmezse baş harf + nadirlik rengi. |
| `widgets/game_card/card_labels.dart` | Tür ve nadirlik adlarının Türkçesi. |
| `widgets/game_card/rarity_frame_painter.dart` | Nadirliğe göre çerçeve çizimi (epik/efsanevide çentikli köşe). |
| `widgets/game_card/holo_layer.dart` | Holo shader katmanı. |
| `widgets/game_card/flip_card.dart` | Dokununca 3B çevirme. |
| `widgets/game_card/tilting_game_card.dart` | Sensör veya sürüklemeyle 3B eğilen kart. |
| `widgets/portal/portal_view.dart` | Shader portal (yoğunluk seviyeleriyle). |
| `widgets/portal/portal_spiral_painter.dart` | Shader yoksa çizilen yedek portal. |
| `widgets/portal_loader.dart` | Yükleme sırasında açılan bekleme portalı. |
| `widgets/shader_cache.dart` | Shader'ları süre sınırıyla yükler ve ısıtır; başarısızsa yedeğe düşer. |
| `widgets/screen_background.dart` | Tam ekran arka plan görseli. |
| `widgets/coin_counter.dart` | Yuvarlanarak değişen coin sayacı. |
| `widgets/app_back_button.dart` | Menü dışındaki her ekrandaki geri butonu (48 dp, buton sesi). |

### 3.10 `lib/features/` – Ekranlar

Her özellik `data/` (depo uygulaması), `domain/` (arayüz) ve `presentation/` (`bloc/`, `pages/`, `widgets/`) olarak bölünmüştür.

| Özellik | Dosyalar ve görevleri |
|---|---|
| **sync** (açılış) | `data/models/*_dto.dart`: API JSON modelleri; `json_reader.dart`: sıkı alan okuma; `mappers.dart`: DTO → varlık; `remote_data_source.dart`: sayfa sayfa indirme; `sync_repository_impl.dart`: kaldığı yerden devam eden senkronizasyon; `bloc/sync_*`: ilerleme durumu; `pages/splash_page.dart`: açılış ekranı ve menüye geçiş; `widgets/sync_status_view.dart`: ilerleme çubuğu ve sayaç. |
| **menu** | `menu_repository*`: coin ve özet; `bloc/menu_*`; `pages/menu_page.dart`: ana menü; `widgets/menu_entry.dart`: menü satırı; `widgets/breathing.dart`: "Portal aç" butonunun nefes alma animasyonu. |
| **portal** | `portal_repository*`: coin düşme, çekiliş ve kaydetme sırası; `bloc/portal_*`: boşta → açılıyor → açılış → açıldı; `pages/portal_page.dart`; `portal_feedback.dart`: portal sesleri ve titreşimleri; `widgets/reveal_scene.dart`, `reveal_stage.dart`, `reveal_timeline.dart`, `reveal_card.dart`, `reveal_effects.dart`: kart açılış sinematiği; `portal_result_view.dart`: kazanılan kart; `shake_hint.dart`: "Telefonu salla!" ipucu. |
| **collection** | `collection_repository*`: sahip olunan kartlar; `bloc/collection_*`: filtre ve sıralama; `bloc/card_detail_*`: kart detayı ve desteye ekleme; `pages/collection_page.dart`, `card_detail_page.dart`; `widgets/collection_grid.dart`, `filter_bar.dart`. |
| **deck** | `bloc/deck_*`: slot doldurma/boşaltma; `pages/deck_page.dart`: toplamlar ve tür kapsaması; `widgets/deck_slots.dart`: üç slot animasyonu. |
| **battle** | `battle_repository*`: deste, rakip ve ödülün bir kez ödenmesi; `bloc/battle_*`: ön-savaş → seçim → tekrar oynatma → sonuç; `battle_feedback.dart`: savaş sesleri ve titreşimleri; `pages/battle_page.dart`: "Savaştan çıkılsın mı?" akışı; `widgets/pre_battle_view.dart`, `battle_stage.dart`, `battle_card_slot.dart`, `event_band.dart`, `battle_cues.dart` ("KRİTİK!", "SÜPER ETKİLİ!"), `hp_bar.dart`, `battle_result_view.dart`. |
| **settings** | `settings_repository*`; `bloc/settings_*`; `pages/settings_page.dart`: ses/müzik/titreşim; `widgets/image_download_tile.dart`: tüm görselleri indir; `widgets/demo_panel.dart`: gizli demo modu (+1000 coin, sıradaki portal efsanevi). |

### 3.11 `lib/l10n/` ve üretilmiş dosyalar

| Dosya | Ne işe yarar |
|---|---|
| `l10n/app_tr.arb` | Tüm Türkçe arayüz metinleri. |
| `l10n/app_localizations*.dart` | Bu metinlerden üretilen kod. |
| `hive_registrar.g.dart` | Hive adaptörlerinin üretilmiş kaydı. |

### 3.12 `android/` – Android ayarları

| Dosya | Ne işe yarar |
|---|---|
| `app/build.gradle.kts` | Paket adı `com.esraergun.portalcards`, sürüm, derleme ayarları. |
| `app/src/main/AndroidManifest.xml` | Tek izin INTERNET; uygulama adı; açık metin (HTTP) trafiği kapalı. |
| `app/src/main/kotlin/.../MainActivity.kt` | Flutter'ı başlatan Android aktivitesi. |
| `res/values*/styles.xml`, `colors.xml`, `drawable*/launch_background.xml` | Koyu (#15112B) açılış ekranı, Android 12+ dahil. |

### 3.13 `test/` – Testler (457 test)

| Klasör | Ne test eder |
|---|---|
| `core/game/` | Oyun motorunun her formülü: nadirlik, tür, istatistik, pasif, savaş olayları, yapay zekâ, portal olasılıkları (10.000 çekiliş), ekonomi, motorun saf Dart olması. |
| `core/…` | Ses, titreşim, sensörler, ağ yeniden deneme, depolama, görsel indirme, kart ve portal bileşenleri (golden görüntü testi dahil), shader önbelleği. |
| `features/…` | Her Bloc (`bloc_test`) ve her ekran (widget testi): açılış, menü, portal, koleksiyon, deste, savaş, ayarlar. |
| `android/` | Release manifest'te INTERNET izni olduğu ve açık metin trafiğinin kapalı olduğu. |
| `app/` | Uygulama açılışı, rotalar, geri navigasyonu, tema kontrastı, token kullanımı (sihirli sayı yasağı), font glifleri. |
| `helpers/`, `fixtures/` | Ortak test yardımcıları, sahte ses ve gerçek API yanıtları. |

### 3.14 `tool/` ve `tools/` – Geliştirme araçları

| Dosya | Ne işe yarar |
|---|---|
| `tool/battle_sim.dart` | Savaş dengesini binlerce maçla simüle eder. |
| `tools/audio/*.py` | Tüm ses efektlerini ve müzikleri kodla (sentezle) üretir; stok ses yok. |
| `tools/icon/generate_icons.py` | Uygulama ikonunu üretir. |
| `tools/images/prepare_backgrounds.py` | Arka plan görsellerini webp'ye hazırlar. |
