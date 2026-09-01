import '../../domain/entities/royalty_free_music_entity.dart';
import '../../domain/entities/store_template_entity.dart';
import '../../domain/repositories/asset_store_repository.dart';
import '../datasources/asset_store_datasource.dart';

class AssetStoreRepositoryImpl implements AssetStoreRepository {
  final AssetStoreDataSource dataSource;

  AssetStoreRepositoryImpl({required this.dataSource});

  @override
  Future<List<StoreTemplateEntity>> getFeaturedTemplates() async {
    return await dataSource.getTemplates();
  }

  @override
  Future<List<RoyaltyFreeMusicEntity>> getMusicCatalog() async {
    return await dataSource.getMusicList();
  }

  @override
  Future<void> downloadAsset(String assetId) async {
    await dataSource.markDownloaded(assetId);
  }
}
