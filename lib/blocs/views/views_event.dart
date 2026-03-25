part of 'views_bloc.dart';

@immutable
sealed class ViewsEvent {}

class CreateViewEvent extends ViewsEvent {
  final String propertyId;
  CreateViewEvent({required this.propertyId});
}
