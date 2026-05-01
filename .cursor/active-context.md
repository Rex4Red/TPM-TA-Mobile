> **BrainSync Context Pumper** 🧠
> Dynamically loaded for active file: `lib\screens\home_screen.dart` (Domain: **Frontend (React/UI)**)

### 📐 Frontend (React/UI) Conventions & Fixes
- **[problem-fix] Fixed null crash in Recommended — prevents null/undefined runtime crashes**: -       final bool isTypeFilter = type != null && type.isNotEmpty && (type == 'project' || type == 'mirror');
+       // Recommended endpoint hanya punya ~7 item (semua Manhwa), jadi skip filter
-       final bool isFormatFilter = type != null && type.isNotEmpty && (type == 'manhwa' || type == 'manhua' || type == 'manga');
+       final bool isRecommended = section == 'recommended';
-       final bool hasFilter = isTypeFilter || isFormatFilter;
+       final bool isTypeFilter = type != null && type.isNotEmpty && (type == 'project' || type == 'mirror');
-       final Map<String, dynamic> params = {};
+       final bool isFormatFilter = type != null && type.isNotEmpty && (type == 'manhwa' || type == 'manhua' || type == 'manga');
-       if (page > 1) params['page'] = page;
+       final bool hasFilter = !isRecommended && (isTypeFilter || isFormatFilter);
-       // Ambil lebih banyak data agar filter client-side tetap menghasilkan cukup item
+       final Map<String, dynamic> params = {};
-       if (hasFilter) params['page_size'] = 50;
+       if (page > 1) params['page'] = page;
- 
+       // Ambil lebih banyak data agar filter client-side tetap menghasilkan cukup item
-       final String endpoint = section == 'recommended' 
+       if (hasFilter) params['page_size'] = 50;
-           ? '$shinigamiUrl/komik/recommended' 
+ 
-           : '$shinigamiUrl/komik/latest';
+       final String endpoint = section == 'recommended' 
- 
+           ? '$shinigamiUrl/komik/recommended' 
-       final response = await _dio.get(endpoint, queryParameters: params);
+           : '$shinigamiUrl/komik/latest';
-       if (response.statusCode == 200 && response.data['retcode'] == 0) {
+       final response = await _dio.get(endpoint, queryParameters: params);
-         final allData = response.data['data'] as List<dynamic>;
+ 
-         
+       if (response.statusCode == 200 && response.data['retcode'] == 0) {
-         // 🔥 CLIENT-SIDE FILTER
+    
… [diff truncated]

📌 IDE AST Context: Modified symbols likely include [ApiService]
