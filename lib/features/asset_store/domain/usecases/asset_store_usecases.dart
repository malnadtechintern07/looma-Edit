import '../entities/royalty_free_music_entity.dart';
import '../entities/store_template_entity.dart';
import '../repositories/asset_store_repository.dart';

class GetStoreTemplatesUseCase {
  final AssetStoreRepository repository;
  const GetStoreTemplatesUseCase(this.repository);

  Future<List<StoreTemplateEntity>> call() => repository.getFeaturedTemplates();
}

class GetMusicCatalogUseCase {
  final AssetStoreRepository repository;
  const GetMusicCatalogUseCase(this.repository);

  Future<List<RoyaltyFreeMusicEntity>> call() => repository.getMusicCatalog();
}

class DownloadAssetUseCase {
  final AssetStoreRepository repository;
  const DownloadAssetUseCase(this.repository);

  Future<void> call(String assetId) => repository.downloadAsset(assetId);
}
