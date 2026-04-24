import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import 'dart:typed_data'; // Import this for Uint8List

class FullSizeImageScreenFile extends StatelessWidget {
  final File? imageFile;
  final int? plotNumber;

  FullSizeImageScreenFile({this.imageFile, this.plotNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo of Plot ${plotNumber ?? 'Loading...'}'),
      ),
      body: Center(
        child: Hero(
          tag: 'imageHero',
          child: imageFile != null ? Image.file(imageFile!, fit: BoxFit.cover) : Container(),
        ),
      ),
    );
  }
}

class FullSizeImageScreen extends StatelessWidget {
  final String? imageUrl;
  final int? plotNumber;
  final DateTime? photoDate;

  FullSizeImageScreen({this.imageUrl, this.plotNumber, this.photoDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo of Plot ${plotNumber ?? 'Loading...'} - ${DateFormat('MMM d, yyyy').format(photoDate!)}'),
      ),
      body: Center(
        child: Hero(
          tag: 'imageHero',
          //child: imageBytes != null ? Image.memory(imageBytes!, fit: BoxFit.cover) : Container(),
          // Use Image.network to display the image from a URL
          child: imageUrl != null ? Image.network(imageUrl!, fit: BoxFit.cover) : Container(),
        ),
      ),
    );
  }
}
