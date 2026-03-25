part of 'share_bloc.dart';

@immutable
sealed class ShareState {}

final class ShareInitial extends ShareState {}

class ShareLoading extends ShareState {}

class ShareSuccess extends ShareState {}

class ShareError extends ShareState {
  final String error;
  ShareError({required this.error});
}
