import 'package:lullify_mobile/domain/entities/stream.dart';

abstract class StreamRepository {
  Future<List<AudioStream>> getActiveStreams();
  Future<AudioStream> getStream(String id);
}
