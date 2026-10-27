import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:pearlnest/apis/api_client.dart';

part 'share_event.dart';
part 'share_state.dart';

class ShareBloc extends Bloc<ShareEvent, ShareState> {
  ShareBloc() : super(ShareInitial()) {
    on<SharePropertyEvent>((event, emit) async {
      emit(ShareLoading());
      try {
        Map<String, dynamic> data = {
          "propertyId": event.propertyId,
        };
        Response response = await ApiClient.post("/shares/add", data);
        print(response.data);
        if (response.statusCode == 200 || response.statusCode == 201) {
        } else {
          emit(ShareError(error: "Sorry, failed to share property details"));
        }
      } catch (e, trace) {
        debugPrint("error:$e");
        debugPrint("location:$trace");
        emit(ShareError(error: "Sorry, failed to share property details"));
      }
    });
  }
}
