import 'package:moonjoin/common/models/module_model.dart';

/// The scope a search query targets — the module the CURRENT search searches.
///
/// Search Scope is a PERMANENT MoonJoin concept, fully independent of the
/// Application Context (`SplashController.module`). Applying a scope must never
/// call `setModule()` / change the active module — it is only used as a
/// per-request `moduleId` header override.
///
/// Future-ready: only [SearchScopeType.module] is exposed today (the backend
/// supports module-scoped search only). New scope types (allModules, nearby,
/// favorites, promotions, trending, aiSearch) can be added later WITHOUT any UI
/// redesign — the selector/sheet are driven by this abstraction, not ModuleModel.
enum SearchScopeType { module /* future: allModules, nearby, favorites, promotions, trending, aiSearch */ }

class SearchScope {
  final SearchScopeType type;
  final ModuleModel? module;

  const SearchScope.module(this.module) : type = SearchScopeType.module;

  /// Value sent as the per-request `moduleId` header override. Null for future
  /// non-module scope types (which the backend does not support yet).
  int? get moduleId => module?.id;

  String get label => module?.moduleName ?? '';
  String? get iconUrl => module?.iconFullUrl ?? module?.thumbnailFullUrl;
}
