part of 'share_bloc.dart';

@immutable
sealed class ShareEvent {}

class SharePropertyEvent extends ShareEvent {
  final String propertyId;
  SharePropertyEvent({required this.propertyId});
}
