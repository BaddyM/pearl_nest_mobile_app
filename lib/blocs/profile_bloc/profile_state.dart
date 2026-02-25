part of 'profile_bloc.dart';

//@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

class ProfileLoadingState extends ProfileState {}

class ProfileLoadedState extends ProfileState {
  final Map<String, dynamic> data;
  ProfileLoadedState({required this.data});
}

class ProfileErrorState extends ProfileState {
  final String? msg;
  ProfileErrorState({this.msg});
}
