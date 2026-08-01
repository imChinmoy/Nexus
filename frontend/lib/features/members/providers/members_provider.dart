import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/data/models/user_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

final membersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final response = await dio.get(ApiConstants.users);
  
  if (response.statusCode == 200) {
    final List<dynamic> data = response.data['data'];
    return data.map((json) => UserModel.fromJson(json).toEntity()).toList();
  } else {
    throw Exception('Failed to load members');
  }
});
