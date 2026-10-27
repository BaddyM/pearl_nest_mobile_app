import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:pearlnest/apis/api_client.dart';

part 'views_event.dart';
part 'views_state.dart';

class ViewsBloc extends Bloc<ViewsEvent, ViewsState> {
  ViewsBloc() : super(ViewsInitial()) {
    on<CreateViewEvent>((event, emit) async {
      emit(ViewsLoading());
      try {
        Map<String, dynamic> data = {};
        Response response = await ApiClient.put("/views/add/${event.propertyId}", data);
        if (response.statusCode == 200 || response.statusCode == 201) {
          emit(ViewsSuccess());
        } else {
          emit(ViewsError(error: "Sorry, failed to add view"));
        }
      } catch (e, trace) {
        debugPrint("Error: $e");
        debugPrint("Location: $trace");
        emit(ViewsError(error: "Sorry, failed to add view"));
      }
    });
  }
}
