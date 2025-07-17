# recon-expl01t

# Bug Bounty Tools Installer & Recon Workflow

## مقدمة

هذا السكربت يقوم بتثبيت مجموعة قوية من أدوات Bug Bounty واختبار الاختراق، لتوفر لك بيئة متكاملة وجاهزة للريكون (جمع المعلومات وفحص الثغرات). الأدوات مخصصة لاكتشاف النطاقات الفرعية، جمع URLs، فحص HTTP، اكتشاف الثغرات، وفحص نقاط الضعف المختلفة.

الأدوات المثبتة تشمل:

- `gau` - لجلب URLs من أرشيف الويب (Google Archive, Wayback Machine)
- `httpx` - فحص الـ HTTP والردود بسرعة عالية
- `subfinder` - اكتشاف النطاقات الفرعية
- `shuffledns` - فحص DNS متعدد الخيوط
- `dalfox` - فحص XSS
- `gf` - قوالب فحص الثغرات (تستخدم مع أدوات أخرى)
- `kxss` - إيجاد نقاط XSS مخفية
- `qsreplace` - استبدال قيم الاستعلام في URL
- `subzy` - فحص النطاقات الفرعية لمعرفة إذا كانت معرضة للاختراق
- `unfurl` - تحليل URLs واستخراج القيم المختلفة منها
- `subjack` - اكتشاف hijacking للنطاقات الفرعية
- `ffuf` - أداة فاززر (fuzzer) متعددة الاستخدامات
- `nuclei` - فحص الثغرات باستخدام قوالب YAML
- `waybackurls` - استخراج URLs من أرشيف Wayback Machine
- `assetfinder` - اكتشاف أسماء النطاقات الفرعية والأصول
- `anew` - فلترة النتائج الجديدة فقط (مثالي لتصفية نتائج الريكون)
- `amass` - جمع معلومات شاملة للنطاقات الفرعية والبنية التحتية

---

## كيفية التثبيت

1. تأكد أن لديك `Go` مثبت (الإصدار 1.23 أو أحدث مفضل).
2. شغل السكربت `install_tools.sh` الموجود مع الأدوات:
   ```bash
   bash install_tools.sh
   ```
3. بعد انتهاء التثبيت، تأكد أن مجلد الأدوات `bin/` موجود في متغير PATH:
   ```bash
   export PATH="$PWD/bin:$PATH"
   ```
   يمكنك إضافته إلى `.bashrc` أو `.zshrc` لتفعيله تلقائيًا.

---

## خوارزمية العمل (Recon Workflow) خطوة بخطوة

### 1. جمع النطاقات الفرعية (Subdomain Enumeration)
- استخدم `amass` و `subfinder` و `assetfinder` لجمع أكبر عدد ممكن من النطاقات الفرعية للنطاق الهدف.
- مثال:
  ```bash
  amass enum -d example.com -o amass.txt
  subfinder -d example.com -o subfinder.txt
  assetfinder --subs-only example.com > assetfinder.txt
  ```

### 2. دمج وفرز النطاقات
- اجمع كل النتائج في ملف واحد وفلتر التكرار:
  ```bash
  cat amass.txt subfinder.txt assetfinder.txt | sort -u > all_subs.txt
  ```

### 3. تحقق من النطاقات الحية (Live Domains)
- استخدم `httpx` لفحص النطاقات الحية (تلك التي ترد على طلب HTTP/HTTPS):
  ```bash
  cat all_subs.txt | httpx -o live_subs.txt
  ```

### 4. جمع الروابط (URLs) للنطاقات الحية
- استخرج الروابط من أرشيفات الإنترنت باستخدام `gau` و `waybackurls`:
  ```bash
  cat live_subs.txt | gau > gau_urls.txt
  cat live_subs.txt | waybackurls > wayback_urls.txt
  cat gau_urls.txt wayback_urls.txt | sort -u > all_urls.txt
  ```

### 5. فلترة الروابط الجديدة فقط
- استخدم `anew` لإزالة الروابط المكررة أو التي تم فحصها مسبقًا:
  ```bash
  cat all_urls.txt | anew old_urls.txt > new_urls.txt
  ```

### 6. فحص الروابط للثغرات (XSS، Open Redirect، وغيرها)
- استخدم `dalfox` و `kxss` لتحليل الروابط واكتشاف نقاط الضعف:
  ```bash
  cat new_urls.txt | dalfox pipe
  cat new_urls.txt | kxss
  ```

### 7. البحث عن hijacking للنطاقات الفرعية
- استخدم `subjack` لفحص النطاقات:
  ```bash
  subjack -w live_subs.txt -t 100 -timeout 30 -o subjack_results.txt
  ```

### 8. البحث عن الثغرات باستخدام قوالب nuclei
- حمل القوالب:
  ```bash
  nuclei -update-templates
  ```
- نفذ الفحص:
  ```bash
  nuclei -l live_subs.txt -t ~/nuclei-templates/ -o nuclei_results.txt
  ```

### 9. استخدام ffuf للفاززنج (Fuzzing)
- مثال على فاززنج:
  ```bash
  ffuf -w wordlist.txt -u https://example.com/FUZZ
  ```

### 10. استخدام gf مع النتائج لتسريع الفحص
- ضع قوالب gf في مجلد `~/.gf/` واستخدمها مع أدوات مثل `ffuf` أو `httpx`.

---

## نصائح هامة

- دائماً حدّث الأدوات والقوالب بانتظام.
- حاول حفظ نتائجك وفلتر الروابط الجديدة لتجنب إعادة الفحص.
- احرص على الالتزام بقوانين البرمجة الأخلاقية واحصل على إذن صريح قبل اختبار أي موقع.
- جرب دمج الأدوات في سكربت واحد لزيادة الكفاءة.

---

## الخلاصة

بإمكانك الآن العمل على بيئة متكاملة ومهنية لإجراء عمليات Bug Bounty بشكل منهجي ومنظم. اتبع الخطوات السابقة وابدأ بجمع المعلومات، فحص الحيّز، ثم البحث عن الثغرات والتقرير عنها.

