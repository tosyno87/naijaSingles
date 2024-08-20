import 'package:flutter/material.dart';

import '../../config/app_config.dart';

class SingleUser {
  static String nearBySingleUserPage({
    final users,
    @required var currentUserLocation,
  }) =>
      '''
 <!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Overlays Within Street View</title>
    <script src="https://polyfill.io/v3/polyfill.min.js?features=default"></script>
    <!-- jsFiddle will insert css and js -->
    <style>
        /* Always set the map height explicitly to define the size of the div
       * element that contains the map. */
        #map {
            height: 100%;
        }
#map div.poi-info-window .view-link {
       display:none;
}
        /* Optional: Makes the sample page fill the window. */
        html,
        body {
            height: 100%;
            margin: 0;
            padding: 0;
        }

       img[src*="#custom_marker"] {
    border: 2px solid #FF3A5A !important;
    border-radius: 50%;
    box-sizing:border-box 
}

       
    </style>
</head>

<body>
   
    <div id="map"></div>

    <!-- Async script executes immediately and must be after any DOM elements used in callback. -->
    <script
        src="https://maps.googleapis.com/maps/api/js?key=$googleMapsKey&callback=initMap&v=weekly&channel=2"
        async></script>
</body>

<script>
    
    let panorama;
var currentUserDetails =
  JSON.parse(JSON.stringify($currentUserLocation));
    function initMap() {
                  // Sample user markers data                                                                            
              var userMarkers1 =
  JSON.parse(JSON.stringify($users));

            // Set the center to the lat/lng of a specific user marker
            const centerUser = userMarkers1[0]; // Change this index as needed
            const centerLatLng = new google.maps.LatLng(centerUser[0].lat, centerUser[0].lng);
        // Set up the map
        const map = new google.maps.Map(document.getElementById("map"), {
            center: centerLatLng??{ lat: 30, lng: 31 },
            zoom:centerLatLng!=null? 14: 2,
            streetViewControl: true,
            zoomControl: false,
              mapTypeControl: false, // Disable map type selection
              fullscreenControl: false, // Disable fullscreen control
              rotateControl: false, // Disable rotate control
              scaleControl: false, // Disable scale control
              panControl: false, 
            streetViewControlOptions: {
   position: google.maps.ControlPosition.TOP_RIGHT,
   
} 
        });
       


  // Create an info window to share between markers.
  const infoWindow = new google.maps.InfoWindow();
    // Create the markers.
    var userMarkers =
  JSON.parse(JSON.stringify($users));
     const markersArray = [];
  userMarkers.forEach(([position, title, icon, id], i) => {
    const image = {
    url: icon + '#custom_marker',
  scaledSize: new google.maps.Size(70, 70),
        origin: new google.maps.Point(0, 0),
        anchor: new google.maps.Point(27.5, 27.5), // Anchor at the center of the circular image
  };

    
    const marker = new google.maps.Marker({
      position,
      map,
      title: title,
      // label: i.toString(),
      icon:image,
      animation: google.maps.Animation.DROP,
      optimized: false,
      
    });
    

   // Add a click listener for each marker, and set up the info window.
    marker.addListener("click", () => {


      const toggle = panorama.getVisible();
     
      if(!toggle){ const sv = new google.maps.StreetViewService();
       sv.getPanorama({ location: marker.getPosition(), radius: 50 })
      .then(processSVData)
      .catch((e) => 
        console.error("Street View data not found for this location.")
        
        
      );
          // Fit the map to show all markers initially
            const bounds = new google.maps.LatLngBounds();
            markersArray.forEach(position => bounds.extend(position));
            map.fitBounds(bounds);
      
    }
     var zoomLevel = map.getZoom();
    if (zoomLevel <= 11) {
    map.setCenter(marker.getPosition());
      map.setZoom(18);
    } 
   
     infoWindow.close();
      infoWindow.setContent(marker.getTitle());
      infoWindow.open(marker.getMap(), marker);
    
    }
    );
  });

     

    // markersArray.push(marker); // Add the marker to the array

    // //  // Calculate bounds to fit all markers and adjust map
    // //     const bounds = new google.maps.LatLngBounds();
    // //     markersArray.forEach(marker => bounds.extend(marker.getPosition()));
    // //     map.fitBounds(bounds);

        // We get the map's default panorama and set up some defaults.
        // Note that we don't yet set it visible.

        panorama = map.getStreetView(); // TODO fix type
         panorama.setOptions({
          addressControl: false
        });
        panorama.setPosition(currentUserDetails);
        panorama.setPov(
    /** @type {google.maps.StreetViewPov} */ {
                heading: 265,
                pitch: 0,
            }
        );
        
    }

function processSVData({ data }) {
console.log(data)
  const location = data.location;
  const marker = new google.maps.Marker({
    position: location.latLng,
    map,
    title: location.description,
  });

  panorama.setPano(location.pano);
  panorama.setPov({
    heading: 270,
    pitch: 0,
  });
  panorama.setVisible(true);
  marker.addListener("click", () => {
    const markerPanoID = location.pano;

    // Set the Pano to use the passed panoID.
    panorama.setPano(markerPanoID);
    panorama.setPov({
      heading: 270,
      pitch: 0,
    });
    panorama.setVisible(true);
  });
}
</script>

</html>
''';
}
