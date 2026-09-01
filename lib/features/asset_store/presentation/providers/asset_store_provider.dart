import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/asset_store_datasource.dart';
import '../../data/repositories/asset_store_repository_impl.dart';
import '../../domain/entities/asset_category.dart';
import '../../domain/entities/royalty_free_music_entity.dart';
import '../../domain/entities/store_template_entity.dart';
import '../../domain/repositories/asset_store_repository.dart';
import '../../domain/usecases/asset_store_usecases.dart';

final assetStoreDataSourceProvider = Provider<AssetStoreDataSource>((ref) {
  return AssetStoreDataSourceImpl();
});

final assetStoreRepositoryProvider = Provider<AssetStoreRepository>((ref) {
  final ds = ref.watch(assetStoreDataSourceProvider);
  return AssetStoreRepositoryImpl(dataSource: ds);
});

final getStoreTemplatesUseCaseProvider = Provider<GetStoreTemplatesUseCase>((ref) {
  return GetStoreTemplatesUseCase(ref.watch(assetStoreRepositoryProvider));
});

final getMusicCatalogUseCaseProvider = Provider<GetMusicCatalogUseCase>((ref) {
  return GetMusicCatalogUseCase(ref.watch(assetStoreRepositoryProvider));
});

final downloadAssetUseCaseProvider = Provider<DownloadAssetUseCase>((ref) {
  return DownloadAssetUseCase(ref.watch(assetStoreRepositoryProvider));
});

final selectedAssetCategoryProvider = StateProvider<AssetCategory>((ref) => AssetCategory.templates);

final storeTemplatesFutureProvider = FutureProvider<List<StoreTemplateEntity>>((ref) async {
  final useCase = ref.watch(getStoreTemplatesUseCaseProvider);
  return await useCase();
});

final musicCatalogFutureProvider = FutureProvider<List<RoyaltyFreeMusicEntity>>((ref) async {
  final useCase = ref.watch(getMusicCatalogUseCaseProvider);
  return await useCase();
});
