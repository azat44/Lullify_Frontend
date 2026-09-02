import 'package:lullify_mobile/data/datasources/stream_remote_datasource.dart';
import 'package:lullify_mobile/domain/entities/stream.dart';
import 'package:lullify_mobile/domain/repositories/stream_repository.dart';

class StreamRepositoryImpl implements StreamRepository {
  StreamRepositoryImpl({required StreamRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final StreamRemoteDataSource _remote;

  @override
  Future<List<AudioStream>> getActiveStreams() async {
    return _remote.getActiveStreams();
  }

  @override
  Future<AudioStream> getStream(String id) async {
    throw UnimplementedError('getStream not implemented yet');
  }
}