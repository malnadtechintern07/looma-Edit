import '../entities/royalty_free_music_entity.dart';
import '../entities/store_template_entity.dart';

abstract class AssetStoreRepository {
  Future<List<StoreTemplateEntity>> getFeaturedTemplates();
  Future<List<RoyaltyFreeMusicEntity>> getMusicCatalog();
  Future<void> downloadAsset(String assetId);
}
