import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../../pitch/domain/repositories/pitch_repository.dart';

abstract class PitchManagementState extends Equatable {
  const PitchManagementState();
  @override
  List<Object?> get props => [];
}

class PitchManagementInitial extends PitchManagementState {}

class PitchManagementLoading extends PitchManagementState {}

class PitchManagementLoaded extends PitchManagementState {
  final List<PitchEntity> pitches;
  final String? message;

  const PitchManagementLoaded(this.pitches, {this.message});

  @override
  List<Object?> get props => [pitches, message];
}

class PitchManagementError extends PitchManagementState {
  final String message;
  const PitchManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Trạng thái đặc biệt: không thể ngưng sân vì bị CONFIRMED block.
class PitchDeactivateBlocked extends PitchManagementState {
  final int confirmedCount;
  final String earliestDeactivationDate;
  const PitchDeactivateBlocked(this.confirmedCount, this.earliestDeactivationDate);

  @override
  List<Object?> get props => [confirmedCount, earliestDeactivationDate];
}

class PitchManagementCubit extends Cubit<PitchManagementState> {
  final PitchRepository repository;

  PitchManagementCubit({required this.repository}) : super(PitchManagementInitial());

  Future<void> loadPitches(String addressId) async {
    emit(PitchManagementLoading());
    try {
      final pitches = await repository.getPitchesByProviderAddressId(addressId);
      emit(PitchManagementLoaded(pitches));
    } catch (e) {
      emit(PitchManagementError(e.toString()));
    }
  }

  void clearMessage() {
    if (state is PitchManagementLoaded) {
      final currentState = state as PitchManagementLoaded;
      emit(PitchManagementLoaded(currentState.pitches, message: null));
    }
  }

  Future<void> createPitch(Map<String, dynamic> data, String addressId) async {
    try {
      await repository.createPitch(data);
      final pitches = await repository.getPitchesByProviderAddressId(addressId);
      emit(PitchManagementLoaded(pitches, message: 'Thêm sân bãi thành công!'));
    } catch (e) {
      emit(PitchManagementError(e.toString()));
    }
  }

  Future<void> updatePitch(String pitchId, Map<String, dynamic> data, String addressId) async {
    try {
      await repository.updatePitch(pitchId, data);
      final pitches = await repository.getPitchesByProviderAddressId(addressId);
      emit(PitchManagementLoaded(pitches, message: 'Cập nhật sân bãi thành công!'));
    } catch (e) {
      emit(PitchManagementError(e.toString()));
    }
  }

  Future<void> deletePitch(String pitchId, String addressId) async {
    try {
      await repository.deletePitch(pitchId);
      final pitches = await repository.getPitchesByProviderAddressId(addressId);
      emit(PitchManagementLoaded(pitches, message: 'Xóa sân bãi thành công!'));
    } catch (e) {
      emit(PitchManagementError(e.toString()));
    }
  }

  Future<void> deactivatePitch(
      String pitchId, String addressId, DateTime targetDate) async {
    try {
      await repository.deactivatePitch(pitchId, targetDate);
      final pitches = await repository.getPitchesByProviderAddressId(addressId);
      emit(PitchManagementLoaded(pitches, message: 'Sân đã được ngưng hoạt động.'));
    } catch (e) {
      final errStr = e.toString();
      // Parse lỗi 409 từ DioException (BE trả về JSON có confirmedBookingCount + earliestDeactivationDate)
      if (errStr.contains('confirmedBookingCount') || errStr.contains('409')) {
        // Extract từ DioException.response.data
        try {
          final dio = e as dynamic;
          final data = dio.response?.data as Map?;
          if (data != null) {
            emit(PitchDeactivateBlocked(
              (data['confirmedBookingCount'] as num?)?.toInt() ?? 0,
              data['earliestDeactivationDate']?.toString() ?? '',
            ));
            return;
          }
        } catch (_) {}
      }
      emit(PitchManagementError(errStr));
    }
  }

  Future<void> reactivatePitch(String pitchId, String addressId) async {
    try {
      await repository.reactivatePitch(pitchId);
      final pitches = await repository.getPitchesByProviderAddressId(addressId);
      emit(PitchManagementLoaded(pitches, message: 'Sân đã được kích hoạt lại.'));
    } catch (e) {
      emit(PitchManagementError(e.toString()));
    }
  }
}
