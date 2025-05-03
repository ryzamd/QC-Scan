import 'package:equatable/equatable.dart';

abstract class CameraState extends Equatable {
  const CameraState();
  
  @override
  List<Object?> get props => [];
}

class CameraInitial extends CameraState {}

class CameraReady extends CameraState {
  final bool isActive;
  final bool isTorchEnabled;
  
  const CameraReady({
    required this.isActive,
    required this.isTorchEnabled,
  });
  
  @override
  List<Object?> get props => [isActive, isTorchEnabled];
}

class CameraInitializing extends CameraState {}

class CameraError extends CameraState {
  final String message;
  
  const CameraError({required this.message});
  
  @override
  List<Object?> get props => [message];
}