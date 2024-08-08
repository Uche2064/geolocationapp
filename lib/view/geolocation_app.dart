import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import the geocoding package for reverse geocoding

class GeolocationApp extends StatefulWidget {
  GeolocationApp({super.key});

  @override
  _GeolocationAppState createState() => _GeolocationAppState();
}

class _GeolocationAppState extends State<GeolocationApp>
    with WidgetsBindingObserver {
  Position? currentLocation;
  String currentAddress = "Unknown";
  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addObserver(this); // Ajoute l'observateur du cycle de vie
    startLocationUpdates();
  }

  @override
  void dispose() {
    positionStream?.cancel(); // Annule le flux lors de la suppression du widget
    WidgetsBinding.instance.removeObserver(this); // Retire l'observateur
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Application passe en arrière-plan ou est inactive
      positionStream?.pause(); // Arrête temporairement le flux
    } else if (state == AppLifecycleState.resumed) {
      // Application revient au premier plan
      positionStream?.resume(); // Reprend le flux
    }
  }

  Future<void> startLocationUpdates() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Prompt the user to enable location services
      return;
    }

    // Check for location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        print(permission);
        return;
      }
    }

    // // Get the current position
    // Position position = await Geolocator.getCurrentPosition(
    //   desiredAccuracy: LocationAccuracy.high,
    // );

    Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.bestForNavigation,
                distanceFilter: 10))
        .listen((Position position) {
      setState(() {
        currentLocation = position;
      });
      updateLocation(); // Update the address when the location changes
    });
  }

  Future<void> updateLocation() async {
    try {
      if (currentLocation != null) {
        // Perform reverse geocoding to get the address from coordinates
        List<Placemark> placemarks = await placemarkFromCoordinates(
          currentLocation!.latitude,
          currentLocation!.longitude,
        );

        Placemark place = placemarks[0];
        setState(() {
          currentAddress =
              "${place.locality}, ${place.country} : ${place.name}";
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    var getContext = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Get User Location "),
      ),
      body: Center(
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Location coordinates ️🗺️",
                  style: getContext.textTheme.headlineLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  )),
              const Gap(10),
              Text(
                currentLocation != null
                    ? "${currentLocation!.latitude}, ${currentLocation!.longitude}"
                    : "Coordinates not available",
                style: getContext.textTheme.bodyLarge!.copyWith(fontSize: 16),
              ),
              const Gap(30),
              Text(
                "Location address 🏠",
                style: getContext.textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Gap(10),
              Text(
                currentAddress,
                style: getContext.textTheme.bodyLarge!.copyWith(fontSize: 16),
              ),
              const Gap(50),
            ],
          ),
        ),
      ),
    );
  }
}
