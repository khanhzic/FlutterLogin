import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:login_app/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileImageWidget extends StatefulWidget {
  final String? profilePhotoPath;
  final double radius;

  const ProfileImageWidget({
    super.key,
    required this.profilePhotoPath,
    this.radius = 40.0,
  });

  @override
  State<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  Uint8List? _cachedImageData;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageData();
  }

  @override
  void didUpdateWidget(ProfileImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profilePhotoPath != widget.profilePhotoPath) {
      _cachedImageData = null;
      _hasError = false;
      _loadImageData();
    }
  }

  Future<void> _loadImageData() async {
    if (widget.profilePhotoPath == null || widget.profilePhotoPath!.isEmpty) {
      return;
    }

    // Check cache first
    final cacheKey = 'profile_image_${widget.profilePhotoPath}';
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    
    if (cachedData != null) {
      try {
        final bytes = base64Decode(cachedData);
        if (mounted) {
          setState(() {
            _cachedImageData = bytes;
            _isLoading = false;
            _hasError = false;
          });
        }
        return;
      } catch (e) {
        // Cache is corrupted, remove it
        await prefs.remove(cacheKey);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final encodedPath = Uri.encodeComponent(widget.profilePhotoPath!);
      final url = '$baseUrl/file/profile-image?file_path=$encodedPath';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'image/*',
          'Cache-Control': 'max-age=3600', // Cache for 1 hour
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        
        // Validate that it's actually an image
        if (contentType != null && contentType.startsWith('image/')) {
          final imageData = response.bodyBytes;
          
          // Cache the image data
          try {
            await prefs.setString(cacheKey, base64Encode(imageData));
          } catch (e) {
            // If caching fails, continue without cache
            print('Failed to cache image: $e');
          }

          if (mounted) {
            setState(() {
              _cachedImageData = imageData;
              _isLoading = false;
              _hasError = false;
            });
          }
        } else {
          throw Exception('Invalid content type: $contentType');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error loading profile image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.profilePhotoPath == null || widget.profilePhotoPath!.isEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        child: const Icon(Icons.person),
      );
    }

    if (_isLoading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.grey[300],
        child: const CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    if (_hasError || _cachedImageData == null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.grey[300],
        child: const Icon(Icons.person),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: MemoryImage(_cachedImageData!),
      onBackgroundImageError: (exception, stackTrace) {
        print('Error displaying profile image: $exception');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      },
    );
  }
} 