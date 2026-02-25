import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:pearlnest/apis/api_client.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial()) {
    on<FetchProfileEvent>((event, emit) async {
      try {
        emit(ProfileLoadingState());
        final Response response = await ApiClient.get("/user/profile");
        if (response.statusCode == 200 || response.statusCode == 201) {
          Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
          emit(ProfileLoadedState(data: data["data"]));
        } else {
          emit(ProfileErrorState(msg: "Sorry, failed to fetch profile"));
        }
      } catch (e, trace) {
        debugPrint("Error: $e");
        debugPrint("Location: $trace");
        emit(ProfileErrorState(msg: "Sorry, failed to fetch profile"));
      }
    });
  }
}
