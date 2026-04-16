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
}
