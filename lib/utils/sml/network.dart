library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix_api_lite/utils/logs.dart';

import 'globals.dart';




void postUrl(Uri uriToPost,
    {String successMessage = 'Sent data', dynamic dataToPost}) {
  Logs().i('Attempting to send post request');
  try {
    Future<http.Response> resp;
    if (dataToPost == null) {
      resp = http.post(
        uriToPost,
      );
    } else {
      final encodedPostData = jsonEncode(dataToPost);
      resp = http.post(
        uriToPost,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: encodedPostData,
      );
    }

    Logs().i('Sent post request');
    resp.then((value) => {
          Logs().i('Received response${value.body}'),
        });
    snackBarKey.currentState?.showSnackBar(SnackBar(
      content: Text(successMessage),
    ));
  } on Error catch (e) {
    Logs().w('Received error posting', e);
    snackBarKey.currentState?.showSnackBar(const SnackBar(
      content: Text('Error sending content to server'),
    ));
  }
}
