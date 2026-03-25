part of 'views_bloc.dart';

@immutable
sealed class ViewsState {}

final class ViewsInitial extends ViewsState {}

class ViewsLoading extends ViewsState {}

class ViewsSuccess extends ViewsState {}

class ViewsError extends ViewsState {
  final String error;
  ViewsError({required this.error});
}
