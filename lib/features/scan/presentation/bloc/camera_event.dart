import 'package:equatable/equatable.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();
  
  @override
  List<Object?> get props => [];
}

class InitializeCamera extends CameraEvent {}

class ToggleCamera extends CameraEvent {
  final bool isActive;
  
  const ToggleCamera({required this.isActive});
  
  @override
  List<Object?> get props => [isActive];
}

class ToggleTorch extends CameraEvent {
  final bool isEnabled;
  
  const ToggleTorch({required this.isEnabled});
  
  @override
  List<Object?> get props => [isEnabled];
}

class SwitchCamera extends CameraEvent {}

class CleanupCamera extends CameraEvent {}